#!/usr/bin/env bash
# Shared dangerous-command matcher — single source of truth for all three tools.
#
#   scripts/guard-command.sh "<command string>"     exit 0 = allow, 2 = block
#   scripts/guard-command.sh --batch <file>         one command per line,
#                                                   prints "<exit>\t<command>"
#
# Exit 2 is what Claude Code, Codex, and Cursor all treat as "deny", so each
# tool's hook only has to extract the command and forward the exit code.
# Batch mode exists so scripts/guard-mutate.sh can evaluate ~1k generated cases
# through the SAME code path in one process; it is not a second implementation.
#
# Fails CLOSED: a missing/empty argument blocks, so an upstream extraction
# failure can never silently disable the guard.
#
# ---------------------------------------------------------------------------
# WHY THIS IS A TOKENIZER AND NOT A LIST OF greps
#
# Every bypass this guard has shipped was the same defect: the RULE was a prose
# quantifier ("root paths", "reads of .env") while the SENSOR was one literal
# spelling. `rm -rf /etc`, `cat ./.env`, `bash -c "rm -rf /etc"` and
# `sudo rm -rf /var` each exited 0 while the docs claimed otherwise. Widening a
# regex loses that race by construction, because the complement of an
# enumeration is infinite.
#
# The mirror-image defect is as expensive: matching a dangerous STRING anywhere
# blocked `git commit -m "block chmod -R 777 in the guard"` and
# `echo "test case: git reset --hard"`. Per README, a guard that blocks ordinary
# work gets deleted, taking the rules that do work with it.
#
# Both come from the same missing abstraction — POSITION. So the command string
# is tokenized quote-aware first, into:
#   * segments      split on ; | & and newline OUTSIDE quotes, plus every
#                   command substitution `$(...)` / backticks / `<(...)` as its
#                   own segment (those execute even inside double quotes)
#   * a command word per segment, found by skipping VAR=value assignments and
#                   privilege/wrapper words, so `sudo` and `env -i` cannot launder
#   * arguments classified by what the command does with them:
#       DATA   echo/printf                  → args are text, never scanned
#       PROSE  git/gh message+search flags  → a commit message is not a command
#       SEARCH grep family                  → the pattern is data, the FILE is not
#       SHELL  bash -c / sh -c / eval / ssh → payload re-enters as a command
#       CODE   python -c / node -e          → foreign code that can hold a DB
#                                             handle: secret-path + SQL rules
#       TEXT   sed / awk / jq programs       → cannot reach a database, so a SQL
#                                             keyword there is a search pattern:
#                                             secret-path rules only
# Quotes are then stripped from the executable view, which is why `rm -rf "/etc"`,
# `bash -c "rm -rf /etc"` and `psql -c "DROP TABLE users"` all match one rule
# each instead of needing one spelling each.
#
# Where an enumeration survives (READERS, the DATA/PROSE/SEARCH command sets) it
# is only in a position where being wrong FAILS CLOSED: an unrecognised reader
# still gets its whole segment scanned, and an unrecognised data command
# over-blocks rather than under-blocks. Enumerations are never load-bearing for
# a target's SHAPE — paths, flags and subcommand positions are derived.
#
# scripts/guard-cases.tsv is the hand-written corpus; scripts/guard-mutate.sh
# mechanically mutates it (prefixes, quoting, wrappers, case) so the corpus can
# no longer be satisfied by one spelling per rule. Both run in scripts/audit.sh.

set -uo pipefail
# Globbing OFF. The root-delete rule iterates `for t in $seg`, and with globbing
# on, a target of `/*` expands against the REAL filesystem before it is looked at.
set -f
# Case-insensitive. SQL keywords are case-insensitive in every engine, so a
# case-sensitive rule made `drop table users` a one-keystroke bypass; same for
# FLUSHALL. Shell command names ARE case-sensitive, so the only cost is
# over-blocking a spelling (`RM -rf /`) that would not have executed anyway.
shopt -s nocasematch

# --- vocabulary --------------------------------------------------------------
# Commands that put a file's CONTENT somewhere an attacker can see it. Wrong
# here = the whole segment is still scanned by every other rule, so a missing
# entry costs precision, not safety.
READERS='cat|bat|less|more|head|tail|nl|od|xxd|hexdump|strings|base64|openssl|source|\.|cp|mv|ln|install|scp|rsync|sftp|tar|zip|unzip|gzip|xz|zstd|tee|dd|split|diff|cmp|file|wc|cut|tr|sort|uniq|pbcopy|gpg|age|vim|nvim|vi|nano|emacs|open|curl|wget|http|grep|rg|ack|ag|awk|sed|jq|yq|xargs|dotenv|python|python3|node|ruby|perl|php'
# Optional quote — harmless leftovers now that quotes are stripped, kept so the
# patterns also work if a caller feeds a raw string past the tokenizer.
Q='["'"'"']?'
# A path prefix glued to a filename: ./x, ../x, /srv/app/x, ~/x.
# It must END IN `/` when non-empty. That single constraint is what stops
# `process.env` and `os.environ.x` matching as if they were paths — an
# identifier before the dot is not a directory — while still catching every
# real prefixed spelling. Putting the exclusion in the TAIL instead broke
# `cat .env` outright, because the preceding space was already consumed.
PFX='([^;|&[:space:]"'"'"']*/)?'

ENV_TAIL='\.env([^[:alnum:]]|$)'
ENV_READ='(^|[[:space:]])('$READERS')[[:space:]]+([^;|&]*[[:space:]])?'$Q$PFX$ENV_TAIL
ENV_REDIR='[<>][[:space:]]*'$Q$PFX$ENV_TAIL
ENV_FLAG='--env-file[[:space:]=]'$Q$PFX$ENV_TAIL

# Copying the shipped example INTO .env is the documented first-run step, not a
# read. Global because both rules_shell and rules_code must consult it, and
# rules_code must consult it BEFORE it strips the example token — stripping
# first turns `cp .env.example .env` into `cp .env`, which is a read.
ENV_FROM_EXAMPLE='\.env\.(example|sample|template|dist)[^;|&]*[[:space:]]+[^;|&]*\.env([^[:alnum:].]|$)'

# Private keys. Two derived shapes plus ssh-keygen's own closed type list:
# anything named id_* under a .ssh directory, and the private-key file
# extensions. `.pub` is excluded by the trailing class — a public key is not a
# secret, and blocking it is the kind of noise that gets a guard deleted.
KEY_TAIL='(\.ssh/id_[[:alnum:]_]+|id_(rsa|dsa|ecdsa|ed25519)(_sk)?|[^[:space:]/]*\.(pem|key|p12|pfx|jks|keystore|ppk))([^[:alnum:].]|$)'
KEY_READ='(^|[[:space:]])('$READERS')[[:space:]]+([^;|&]*[[:space:]])?'$Q$PFX$KEY_TAIL

# Agent policy surface. aidlc/rules/security.md: a session that can write these
# grants itself capability in the NEXT session, so the write is a privilege
# escalation even when the diff looks harmless. Scope is derived from the path —
# the whole adapter directory, not a list of filenames — plus .git/hooks, which
# executes on every commit.
# The leading context is a NEGATED class, not a list of delimiters. Listing
# `space`, `=` and `/` looked complete until a code payload spelled it
# `open('.claude/settings.json','w')` — preceded by a quote, matched nothing.
# "not a filename character" covers every delimiter, present and future, while
# still refusing to match a suffix like `myapp.claude/`.
# Scope is the CAPABILITY surface, not the whole adapter directory. What grants
# the next session power is the permission/hook config and an agent's `tools:`
# list; `rules/` and `skills/` are advisory prose to a model, and editing them is
# ordinary work — the very work this template exists for. Blocking the whole tree
# blocked a maintainer editing a rule file, and per README a guard that blocks
# ordinary work gets deleted, taking the rules that do work with it.
POLICY_PATH='(settings(\.local)?\.json|hooks\.json|hooks/[^[:space:]]*|agents/[^[:space:]]*|config\.toml)'
POLICY='(^|[^[:alnum:]_.-])\.(claude|cursor|codex)/'$POLICY_PATH'|(^|[^[:alnum:]_.-])\.git/hooks(/|[[:space:]]|$)'
POLICY_REDIR='[>][[:space:]]*'$Q'[^[:space:]]*(\.(claude|cursor|codex)/'$POLICY_PATH'|\.git/hooks/)'

# --- state -------------------------------------------------------------------
Q_TXT=(); Q_SEP=()
SEG_SEP=(); SEG_TXT=(); SEG_CW=(); SEG_S1=(); SEG_S2=(); SEG_LAST=()

block() { echo "Blocked by scripts/guard-command.sh: $1" >&2; exit 2; }

push_q() { Q_TXT[${#Q_TXT[@]}]=$1; Q_SEP[${#Q_SEP[@]}]=$2; }

add_seg() { # sep, text, cmdword, sub1, sub2, last-word
  local i=${#SEG_TXT[@]}
  SEG_SEP[i]=$1; SEG_TXT[i]=$2; SEG_CW[i]=$3; SEG_S1[i]=$4; SEG_S2[i]=$5; SEG_LAST[i]=$6
}

# --- pass 1: segment the command, quote-aware --------------------------------
grab_paren() { # text, index of '(' -> GRAB_TXT, GRAB_END
  local s=$1 i=$2 n=${#1} d=0 c inner=''
  while [ "$i" -lt "$n" ]; do
    c=${s:i:1}
    if [ "$c" = '(' ]; then
      d=$((d+1))
      if [ "$d" -eq 1 ]; then i=$((i+1)); continue; fi
    elif [ "$c" = ')' ]; then
      d=$((d-1))
      if [ "$d" -eq 0 ]; then GRAB_TXT=$inner; GRAB_END=$((i+1)); return 0; fi
    fi
    inner=$inner$c; i=$((i+1))
  done
  GRAB_TXT=$inner; GRAB_END=$n
}

grab_backtick() { # text, index of '`' -> GRAB_TXT, GRAB_END
  local s=$1 i=$(($2 + 1)) n=${#1} inner=''
  while [ "$i" -lt "$n" ] && [ "${s:i:1}" != '`' ]; do inner=$inner${s:i:1}; i=$((i+1)); done
  GRAB_TXT=$inner; GRAB_END=$((i+1))
}

split_cmd() { # text, separator that introduced it
  local s=$1 sep=$2 n=${#1} i=0 c q='' cur=''
  while [ "$i" -lt "$n" ]; do
    c=${s:i:1}
    if [ -n "$q" ]; then
      # Inside quotes nothing separates commands — EXCEPT substitution inside
      # double quotes, which still executes: `echo "$(cat .env)"` is a read.
      if [ "$c" = "$q" ]; then q=''; cur=$cur$c; i=$((i+1)); continue; fi
      if [ "$q" = '"' ] && [ "$c" = '$' ] && [ "${s:i+1:1}" = '(' ]; then
        grab_paren "$s" $((i+1)); push_q "$GRAB_TXT" '$'; i=$GRAB_END; continue
      fi
      if [ "$q" = '"' ] && [ "$c" = '`' ]; then
        grab_backtick "$s" "$i"; push_q "$GRAB_TXT" '$'; i=$GRAB_END; continue
      fi
      cur=$cur$c; i=$((i+1)); continue
    fi
    case $c in
      "'"|'"') q=$c; cur=$cur$c; i=$((i+1)) ;;
      '\') cur=$cur$c${s:i+1:1}; i=$((i+2)) ;;
      '$')
        if [ "${s:i+1:1}" = '(' ]; then
          grab_paren "$s" $((i+1)); push_q "$GRAB_TXT" '$'; i=$GRAB_END
        else cur=$cur$c; i=$((i+1)); fi ;;
      '`') grab_backtick "$s" "$i"; push_q "$GRAB_TXT" '$'; i=$GRAB_END ;;
      '<'|'>')
        if [ "${s:i+1:1}" = '(' ]; then
          grab_paren "$s" $((i+1)); push_q "$GRAB_TXT" '<'; i=$GRAB_END
        else cur=$cur$c; i=$((i+1)); fi ;;
      ';'|'|'|'&'|$'\n')
        emit_seg "$cur" "$sep"; cur=''
        if [ "${s:i+1:1}" = "$c" ]; then sep=$c$c; i=$((i+2)); else sep=$c; i=$((i+1)); fi ;;
      # A bare `(` opens a SUBSHELL, i.e. a fresh command position. Without this,
      # `( npm publish )` put `(` in the command slot and every
      # subcommand-position rule missed it. `$(`/`<(` are consumed above, and an
      # escaped `\(` (find -exec) is consumed by the escape arm, so neither
      # reaches here. `{ ... }` is deliberately NOT a separator: `${HOME}` would
      # shred into `$` + `HOME` and un-anchor the root-delete rule.
      '('|')')
        emit_seg "$cur" "$sep"; cur=''; sep=$c; i=$((i+1)) ;;
      '#')
        # A comment runs to end of LINE, not end of segment. Truncating per
        # segment instead meant `ls # cp .env.example x; cat .env` still blocked
        # on text the shell never executes. Only a word-INITIAL `#` starts one,
        # so `curl http://x#frag` and `sed s/#/y/` are untouched.
        case $cur in
          ''|*[[:space:]]) while [ "$i" -lt "$n" ] && [ "${s:i:1}" != $'\n' ]; do i=$((i+1)); done ;;
          *) cur=$cur$c; i=$((i+1)) ;;
        esac ;;
      *) cur=$cur$c; i=$((i+1)) ;;
    esac
  done
  emit_seg "$cur" "$sep"
}

# --- pass 2: words, command position, argument classification ----------------
emit_seg() { # raw segment, separator
  local raw=$1 sep=$2
  case $raw in *[![:space:]]*) ;; *) return 0 ;; esac

  local W=() WQ=()
  local n=${#raw} i=0 c q='' cur='' started=0 wasq=0
  while [ "$i" -lt "$n" ]; do
    c=${raw:i:1}
    if [ -n "$q" ]; then
      if [ "$c" = "$q" ]; then q=''; else cur=$cur$c; fi
      i=$((i+1)); continue
    fi
    case $c in
      "'"|'"') q=$c; wasq=1; started=1; i=$((i+1)) ;;
      ' '|$'\t'|$'\n')
        if [ "$started" = 1 ]; then W[${#W[@]}]=$cur; WQ[${#WQ[@]}]=$wasq; cur=''; started=0; wasq=0; fi
        i=$((i+1)) ;;
      '\') cur=$cur${raw:i+1:1}; started=1; i=$((i+2)) ;;
      *) cur=$cur$c; started=1; i=$((i+1)) ;;
    esac
  done
  [ "$started" = 1 ] && { W[${#W[@]}]=$cur; WQ[${#WQ[@]}]=$wasq; }
  [ ${#W[@]} -eq 0 ] && return 0

  # A `#` comment is not an executable position. Only an UNQUOTED word can start
  # one, which the quote flags make exact rather than guessed.
  local k wc=${#W[@]}
  for ((k=0; k<wc; k++)); do
    if [ "${WQ[k]}" = 0 ]; then case ${W[k]} in '#'*) wc=$k; break ;; esac; fi
  done

  # Command position: skip VAR=value and privilege/wrapper words so a `sudo`,
  # `env -i` or `xargs` prefix cannot launder the command behind it.
  local ci=0 w
  while [ "$ci" -lt "$wc" ]; do
    w=${W[ci]}
    case $w in
      [A-Za-z_]*=*) ci=$((ci+1)); continue ;;
      -*) ci=$((ci+1)); continue ;;
    esac
    case ${w##*/} in
      sudo|doas|su|env|nice|nohup|time|command|builtin|exec|setsid|stdbuf|ionice|caffeinate|timeout|xargs|nix-shell)
        ci=$((ci+1)); continue ;;
      # Shell keywords and grouping are never the command. Without this,
      # `{ npm publish; }` put `{` in the command slot and the subcommand-position
      # rules missed it. Skipping the keyword is exact; the alternative (also
      # testing the SECOND operand pair) over-fired on `tar -czf x.tgz publish`.
      '{'|'}'|'!'|if|then|elif|else|fi|do|done|while|until|for|case|esac)
        ci=$((ci+1)); continue ;;
    esac
    break
  done
  local cw=''
  [ "$ci" -lt "$wc" ] && cw=${W[ci]##*/}

  # Subcommand positions, taken before filtering: `publish`, `destroy`,
  # `uninstall` are dangerous BECAUSE of where they sit, not because of spelling.
  local s1='' s2=''
  for ((k=ci+1; k<wc; k++)); do
    case ${W[k]} in -*) continue ;; esac
    if [ -z "$s1" ]; then s1=${W[k]}; continue; fi
    s2=${W[k]}; break
  done

  local K=() skipval=0 codeflag=0 pat_taken=0 pk=C
  case $cw in
    echo|printf|:|true|false)
      # Arguments are TEXT. Redirections are shell syntax, not arguments, so
      # `echo x > .env` still writes a secret file and still blocks.
      K[0]=$cw
      for ((k=ci+1; k<wc; k++)); do
        if [ "${WQ[k]}" = 0 ] && [[ ${W[k]} =~ [\<\>] ]]; then
          K[${#K[@]}]=${W[k]}
          [ $((k+1)) -lt "$wc" ] && K[${#K[@]}]=${W[k+1]}
        fi
      done ;;
    grep|egrep|fgrep|rg|ag|ack|ugrep)
      # The PATTERN is data; the FILE operand is not. `grep SECRET .env` blocks,
      # `grep -r "rm -rf /" scripts/` does not.
      for ((k=ci; k<wc; k++)); do
        w=${W[k]}
        if [ "$skipval" = 1 ]; then skipval=0; continue; fi
        case $w in
          -e|--regexp|-f|--file) skipval=1; pat_taken=1; K[${#K[@]}]=$w; continue ;;
          --include|--exclude|--exclude-dir|--glob|-g) skipval=1; K[${#K[@]}]=$w; continue ;;
          -*) K[${#K[@]}]=$w; continue ;;
        esac
        if [ "$pat_taken" = 0 ] && [ "$k" -gt "$ci" ]; then pat_taken=1; continue; fi
        K[${#K[@]}]=$w
      done ;;
    git|gh|hub|glab|jj|hg|svn|bzr)
      # Prose. Every dangerous VCS form is spelled with unquoted flags
      # (`push -f`, `reset --hard`, `clean -xfd`), so dropping quoted operands
      # and message/search flag VALUES costs no coverage and kills the entire
      # "commit message describes a dangerous command" false-positive class.
      for ((k=ci; k<wc; k++)); do
        w=${W[k]}
        if [ "$skipval" = 1 ]; then skipval=0; continue; fi
        case $w in
          -m|--message|-F|--file|--body|--body-file|--title|--notes|--description|--grep|--author|--committer|-c)
            skipval=1; K[${#K[@]}]=$w; continue ;;
          --message=*|--body=*|--body-file=*|--title=*|--notes=*|--description=*|--grep=*|--author=*|--committer=*|--file=*)
            continue ;;
        esac
        [ "${WQ[k]}" = 1 ] && continue
        K[${#K[@]}]=$w
      done ;;
    bash|sh|zsh|dash|ksh|mksh|ash|fish|eval|ssh)
      # Payload is SHELL. Re-enter it as a command: `bash -c "rm -rf /etc"` is
      # `rm -rf /etc`, and treating it as an opaque string is how it exited 0.
      for ((k=ci; k<wc; k++)); do
        w=${W[k]}
        if [ "$codeflag" = 1 ]; then codeflag=0; push_q "$w" '^'; continue; fi
        case $w in -c|--command) codeflag=1; K[${#K[@]}]=$w; continue ;; esac
        if [ "${WQ[k]}" = 1 ] && [ "$k" -gt "$ci" ]; then push_q "$w" '^'; continue; fi
        K[${#K[@]}]=$w
      done ;;
    python|python2|python3|node|deno|bun|ruby|perl|php|osascript|sed|awk|gawk|mawk|nawk|jq|yq|ruby18)
      # Payload is FOREIGN code. Scanning it as shell text false-blocked
      # `sed 's|rm -rf /|x|' f` (split on sed's own delimiter), so it is queued
      # as a code payload: secret-path rules only, never the shell rules.
      #
      # Two kinds, split by CAPABILITY rather than by name: a language runtime
      # can hold a database handle, so SQL rules apply to it (kind C); sed, awk
      # and jq cannot talk to a database, so a SQL keyword in their program is a
      # search pattern, not a statement (kind T). Applying SQL rules to both
      # blocked `sed -n '/DROP TABLE/p' migrations/003.sql`.
      pk=C
      case $cw in sed|awk|gawk|mawk|nawk|jq|yq) pk=T ;; esac
      for ((k=ci; k<wc; k++)); do
        w=${W[k]}
        if [ "$codeflag" = 1 ]; then codeflag=0; push_q "$w" "$pk"; continue; fi
        case $w in
          -c|-e|-E|-p|-l|--eval|--expr|-n)
            case $w in -n) K[${#K[@]}]=$w; continue ;; esac
            codeflag=1; K[${#K[@]}]=$w; continue ;;
          -*) K[${#K[@]}]=$w; continue ;;
        esac
        case $cw in
          sed|awk|gawk|mawk|nawk|jq|yq)
            if [ "$pat_taken" = 0 ] && [ "$k" -gt "$ci" ]; then
              pat_taken=1; push_q "$w" "$pk"; continue
            fi ;;
        esac
        K[${#K[@]}]=$w
      done ;;
    *)
      for ((k=ci; k<wc; k++)); do K[${#K[@]}]=${W[k]}; done ;;
  esac

  # Scaffolding filenames are exempt at WORD level, not by substring. Testing
  # the exemption against the whole segment let a benign mention disarm a real
  # read on the same line: `cat .env.example && cat .env` exited 0.
  # A copy FROM the example INTO .env is the documented first-run step. Dropping
  # only the example word left `cp .env`, which is indistinguishable from a read,
  # so setup was blocked. Detect the pair here — where both words are still
  # visible — and drop the destination too.
  local has_example=0 setup=0
  for ((k=0; k<${#K[@]}; k++)); do
    case ${K[k]} in
      *.env.example*|*.env.sample*|*.env.template*|*.env.dist*) has_example=1 ;;
    esac
  done
  case $cw in
    cp|mv|ln|install|rsync) [ "$has_example" -eq 1 ] && setup=1 ;;
  esac

  local K2=()
  for ((k=0; k<${#K[@]}; k++)); do
    case ${K[k]} in
      *.env.example*|*.env.sample*|*.env.template*|*.env.dist*) continue ;;
    esac
    if [ "$setup" -eq 1 ]; then
      case ${K[k]} in
        .env|*/.env) continue ;;
      esac
    fi
    K2[${#K2[@]}]=${K[k]}
  done
  [ ${#K2[@]} -eq 0 ] && return 0

  local last=${K2[$((${#K2[@]} - 1))]}
  add_seg "$sep" "${K2[*]}" "$cw" "$s1" "$s2" "$last"
}

tokenize() {
  Q_TXT=("$1"); Q_SEP=('^')
  SEG_SEP=(); SEG_TXT=(); SEG_CW=(); SEG_S1=(); SEG_S2=(); SEG_LAST=()
  local qi=0
  while [ "$qi" -lt "${#Q_TXT[@]}" ]; do
    if [ "${Q_SEP[qi]}" = 'C' ] || [ "${Q_SEP[qi]}" = 'T' ]; then
      add_seg "${Q_SEP[qi]}" "${Q_TXT[qi]}" '' '' '' ''
    else
      split_cmd "${Q_TXT[qi]}" "${Q_SEP[qi]}"
    fi
    qi=$((qi+1))
  done
}

# --- rules -------------------------------------------------------------------
sql_rules() { # $1 = text
  # The object keyword is OPTIONAL: `TRUNCATE users` and `DROP INDEX ix` are
  # valid SQL in every engine and both used to exit 0, because the rule required
  # TABLE|DATABASE|SCHEMA. Keep the regex in a variable — a literal backtick
  # inside [[ =~ ]] opens command substitution and breaks the script.
  local SQL_DESTRUCTIVE='(DROP|TRUNCATE)[[:space:]]+((TABLE|DATABASE|SCHEMA|VIEW|INDEX)[[:space:]]+)?[[:alnum:]_."]+'
  [[ $1 =~ $SQL_DESTRUCTIVE ]] &&
    block "destructive SQL (DROP/TRUNCATE)"
  [[ $1 =~ DELETE[[:space:]]+FROM[[:space:]]+[[:alnum:]_.\"]+[[:space:]]*(\;|\"|$) ]] &&
    block "unbounded DELETE (no WHERE clause)"
  return 0
}

secret_rules() { # $1 = text (already example-stripped by the caller)
  # A bare $ENV_TAIL here matched `process.env.PORT` and `os.environ`, because in
  # a code payload there is no reader/position context to lean on. Require the
  # PATH shape: `.env` must not be preceded by an identifier character, since an
  # identifier before the dot is a property access, not a directory.
  local ENV_AS_PATH='(^|[^[:alnum:]_.])'$Q$PFX'\.env([^[:alnum:]]|$)'
  [[ $1 =~ $ENV_AS_PATH ]] &&
    block "reads or writes a .env file — take secrets from your secrets manager, not the shell"
  [[ $1 =~ $KEY_TAIL ]] && block "reads a private key file"
  # Deliberately NOT checking $POLICY here. This runs on foreign code payloads
  # where read and write cannot be told apart, and it blocked
  # `python3 -c "json.load(open('.cursor/hooks.json'))"` — an ordinary read.
  # Writes are still caught in rules_shell, where the command word gives the
  # direction. Accepted gap: a code one-liner that writes a policy file. Those
  # files are git-tracked, so the change shows in a diff and reverts.
  return 0
}

rules_code() { # foreign code payload: $2 = C (language runtime) or T (text tool)
  local t=$1 p
  # Order matters. Strip the example token only AFTER deciding whether this is
  # the setup shape, and when it is, remove the destination as well — otherwise
  # `cp .env.example .env` reduces to `cp .env` and blocks first-run setup.
  [[ $t =~ $ENV_FROM_EXAMPLE ]] && t=${t//.env/}
  for p in example sample template dist; do t=${t//.env.$p/}; done
  secret_rules "$t"
  [ "$2" = C ] && sql_rules "$t"
  return 0
}

rules_shell() {
  local seg=$1 cw=$2 s1=$3 s2=$4 last=$5 t

  # Recursive force-delete of a root-anchored path. The target's SHAPE is the
  # rule — anything anchored at /, ~ or $HOME at any depth — because the old
  # form required the target to BE one of four literal spellings and `rm -rf
  # /etc` exited 0 while README claimed root paths were blocked. Relative
  # targets and temp roots stay allowed: `rm -rf build/` is ordinary work.
  if [[ $seg =~ (^|[[:space:]])rm([[:space:]]|$) ]] &&
     [[ $seg =~ (-[[:alnum:]-]*[rR]|--recursive) ]] &&
     [[ $seg =~ (-[[:alnum:]-]*[fF]|--force) ]]; then
    for t in $seg; do
      case $t in
        /*|'~'*|'$HOME'*|'${HOME}'*) ;;
        *) continue ;;
      esac
      case $t in
        /tmp|/tmp/*|/private/tmp|/private/tmp/*|/var/folders/*|/var/tmp/*) continue ;;
        # A cache rebuilds from a registry, so clearing one is routine and
        # blocking it is noise. Anchored to known cache roots, not any path
        # containing the word cache.
        */.cache|*/.cache/*|*/Library/Caches|*/Library/Caches/*) continue ;;
        */.npm/*|*/.yarn/cache/*|*/.pnpm-store/*|*/.gradle/caches/*|*/.m2/repository/*) continue ;;
        */node_modules|*/node_modules/*|*/.venv|*/.venv/*) continue ;;
      esac
      block "recursive force-delete of a root-anchored path: $t"
    done
  fi

  # git push --force. --force-with-lease is the safe form and stays allowed.
  if [[ $seg =~ (^|[[:space:]])git[[:space:]]+push([[:space:]]|$) ]] &&
     [[ $seg =~ (--force([[:space:]]|$)|(^|[[:space:]])-f([[:space:]]|$)) ]] &&
     [[ ! $seg =~ --force-with-lease ]]; then
    block "git push --force (prefer --force-with-lease; never on main/master)"
  fi

  # Recursive chmod granting write to OTHERS. Derived from the bit, not from a
  # list of mode strings: numerically the last octal digit carries others-write
  # (2,3,6,7); symbolically the class must actually name `o` or `a`. Kept when
  # the reversible rules were dropped because no benign command in the
  # false-positive corpus triggers it, and `chmod -R 777 /` is not reversible in
  # practice even though each bit technically is.
  if [[ $seg =~ (^|[[:space:]])chmod([[:space:]]|$) ]] &&
     [[ $seg =~ (-[[:alnum:]-]*R|--recursive) ]] &&
     [[ $seg =~ ([[:space:]][0-7]?[0-7][0-7][2367]([[:space:]]|$)|(^|[[:space:]])[ugoa]*[oa][ugoa]*\+[rwxXst]*w) ]]; then
    block "recursive chmod granting write to others"
  fi

  # Secret files, in a file-consuming POSITION. Matching .env anywhere is what
  # blocked `git commit -m "fix .env handling"`, and a guard that blocks
  # committing protects nothing because it gets removed.
  # Direction matters. READING .env moves secrets somewhere they can be seen.
  # CREATING .env from the shipped example is the documented first-run step, and
  # --env-file is how compose is normally invoked; blocking either taught
  # nothing and blocked setup.
  # Regex in a variable: an unquoted `;` or `|` inside [[ =~ ]] is parsed as
  # shell syntax, not as part of the pattern.
  ENV_SETUP=0
  [[ $seg =~ $ENV_FROM_EXAMPLE ]] && ENV_SETUP=1
  if [[ $ENV_SETUP -eq 0 ]] && { [[ $seg =~ $ENV_READ ]] || [[ $seg =~ $ENV_REDIR ]]; }; then
    block "reads a .env file — take secrets from your secrets manager, not the shell"
  fi
  # `openssl genrsa -out server.key` CREATES a key. Only reads are disclosure.
  if [[ ! $seg =~ (^|[[:space:]])(genrsa|genpkey|req|ecparam|keygen)([[:space:]]|$) ]]; then
    [[ $seg =~ $KEY_READ ]] &&
      block "reads a private key file — keys never pass through the shell"
  fi

  # Agent policy writes. Reads stay allowed (`cat .claude/settings.json`,
  # `jq empty .claude/settings.json`) — only a writer in the command position or
  # a redirect into the path is capability escalation.
  if [[ $seg =~ $POLICY_REDIR ]]; then
    block "writes an agent policy file — that grants capability to the next session (aidlc/rules/security.md)"
  fi
  case $cw in
    tee|dd|truncate|install|patch|chmod|chown|chgrp|touch|mkdir|rmdir|rm|shred|unlink)
      [[ $seg =~ $POLICY ]] &&
        block "writes an agent policy file — that grants capability to the next session (aidlc/rules/security.md)" ;;
    cp|mv|ln|rsync|scp)
      [[ $last =~ $POLICY ]] &&
        block "writes an agent policy file — that grants capability to the next session (aidlc/rules/security.md)" ;;
    sed)
      if [[ $seg =~ (^|[[:space:]])-[[:alnum:]]*i ]] && [[ $seg =~ $POLICY ]]; then
        block "writes an agent policy file — that grants capability to the next session (aidlc/rules/security.md)"
      fi ;;
  esac

  # Irreversible publish / release, derived from the SUBCOMMAND POSITION: any
  # tool whose first or second operand is `publish` is publishing, so a package
  # manager the template has never heard of is covered too.
  #
  # One enumeration survives, and it is on the exemption side ON PURPOSE.
  # `ls publish` and `npm publish` are the same shape — position alone cannot
  # separate them, so something has to know which commands take a PATH where
  # others take a subcommand. Enumerating path-operand commands fails open only
  # for those commands, and none of them has a publish subcommand (a closed,
  # checkable claim). Enumerating package managers instead would fail open for
  # every tool invented after this line was written — the exact defect class
  # this guard was rebuilt to remove.
  local dry=0
  [[ $seg =~ (--dry-run|--dryrun|--dry_run) ]] && dry=1
  case $cw in
    ls|cd|cat|rm|cp|mv|mkdir|rmdir|touch|find|open|tree|du|df|stat|file|wc|head|tail|less|more|code|vim|nvim|nano|echo|printf)
      dry=1 ;;
  esac
  if [ "$dry" = 0 ]; then
    case "$cw/$s1" in
      # `dotnet publish` is a LOCAL build step (it writes a publish/ folder).
      # dotnet's registry push is `dotnet nuget push`, matched below — so the
      # exemption has to be this narrow, not the whole `dotnet` tool.
      dotnet/publish) ;;
      */publish|*/unpublish) block "publishes a package to a registry (irreversible)" ;;
      gem/push|twine/upload) block "publishes a package to a registry (irreversible)" ;;
      dotnet/nuget) [ "$s2" = push ] && block "publishes a package to a registry (irreversible)" ;;
    esac
    # Maven's publish is a lifecycle phase, so it can sit behind other phases
    # (`mvn clean deploy`). `deploy` is NOT generalised to other tools: `fly
    # deploy`, `cdk deploy` and `vercel deploy` are ordinary work, and blocking
    # every deploy is how a guard gets deleted.
    if [[ $seg =~ (^|[[:space:]])mvn[[:space:]] ]] && [[ $seg =~ (^|[[:space:]])deploy([[:space:]]|$) ]]; then
      block "publishes a package to a registry (irreversible)"
    fi
  fi
  # Store submission is a release, not a build: `fastlane scan` and `fastlane
  # build` stay allowed. Matched on the segment so `( fastlane deliver )` and a
  # sudo/env prefix cannot launder it.
  if [[ $seg =~ (^|[[:space:]])fastlane[[:space:]]([^;|&]*[[:space:]])?(deliver|supply|pilot|upload_to_[[:alnum:]_]+)([[:space:]]|$) ]] ||
     { [[ $seg =~ (^|[[:space:]])altool([[:space:]]|$) ]] && [[ $seg =~ --upload ]]; }; then
    block "submits a build to an app store (irreversible)"
  fi

  # A preview is not an action. --dry-run / -n, and `terraform plan`, mean
  # nothing happens. Blocking a preview is pure noise, and one gate here beats
  # bolting the exception onto each teardown rule and forgetting one.
  # Long form ONLY. A bare `-n` is NOT a dry-run flag in the tools this gate
  # covers: it selects the namespace in kubectl and helm and the database index
  # in redis-cli, so treating it as "preview" would exempt `redis-cli -n 0
  # flushdb` — a real wipe. Verified: that case is in guard-cases.tsv as expect-2.
  DRYRUN=0
  [[ $seg =~ (--dry-run|--dryrun) ]] && DRYRUN=1
  [[ $seg =~ (^|[[:space:]])(terraform|tofu|terragrunt)[[:space:]]([^;|&]*[[:space:]])?plan([[:space:]]|$) ]] && DRYRUN=1

  # Live-infrastructure teardown. Matched on the segment with the tool name in
  # the pattern rather than on the command word alone, so subshell grouping and
  # wrapper prefixes cannot move the tool out of the checked position.
  if [[ $seg =~ (^|[[:space:]])helm[[:space:]]([^;|&]*[[:space:]])?(uninstall|delete)([[:space:]]|$) ]]; then
    { [[ $DRYRUN -eq 1 ]] || block "helm uninstall removes a live release"; }
  fi
  if [[ $seg =~ (^|[[:space:]])(terraform|tofu|terragrunt)[[:space:]] ]] &&
     [[ $seg =~ (^|[[:space:]])-?destroy([[:space:]]|$) ]]; then
    { [[ $DRYRUN -eq 1 ]] || block "terraform destroy tears down live infrastructure"; }
  fi
  if [[ $seg =~ (^|[[:space:]])(kubectl|oc)[[:space:]] ]] &&
     [[ $seg =~ (^|[[:space:]])delete([[:space:]]|$) ]] &&
     [[ $seg =~ (^|[[:space:]])(ns|namespace|namespaces|crd|customresourcedefinitions?|pvc|pv|nodes?)([[:space:]]|$) ]]; then
    { [[ $DRYRUN -eq 1 ]] || block "kubectl delete of a namespace or a whole resource class"; }
  fi
  if [[ $seg =~ (^|[[:space:]])(redis-cli|valkey-cli|iredis)[[:space:]] ]] &&
     [[ $seg =~ (^|[[:space:]])flush(all|db)([[:space:]]|$) ]]; then
    { [[ $DRYRUN -eq 1 ]] || block "redis FLUSHALL/FLUSHDB wipes the datastore"; }
  fi

  # Printing a credential puts it in a transcript, which is the one place a
  # secret can never be revoked from.
  if [[ $seg =~ (^|[[:space:]])(gh|glab|hub)[[:space:]]+auth[[:space:]]+token ]] ||
     [[ $seg =~ (print-access-token|print-identity-token|get-access-token|get-secret-value|--with-decryption) ]] ||
     [[ $seg =~ (^|[[:space:]])security[[:space:]]+find-(generic|internet)-password ]] ||
     { [[ $seg =~ (^|[[:space:]])(kubectl|oc)[[:space:]] ]] &&
       [[ $seg =~ (^|[[:space:]])get[[:space:]]+secrets?([[:space:]]|$) ]] &&
       [[ $seg =~ (-o|--output)[[:space:]=]+(yaml|json) ]]; }; then
    block "prints a credential into the transcript — read it from the secrets manager instead"
  fi

  sql_rules "$seg"
  return 0
}

# A downloader piped straight into an interpreter executes code nobody reviewed.
# Checked across the segment BOUNDARY, using the separator the tokenizer
# recorded, so `curl x || echo y` is not mistaken for `curl x | sh`.
pipeline_rules() {
  local i prev=''
  for ((i=0; i<${#SEG_TXT[@]}; i++)); do
    if [ "${SEG_SEP[i]}" = '|' ] || [ "${SEG_SEP[i]}" = '<' ]; then
      local a=$prev b=${SEG_TXT[i]}
      [ "${SEG_SEP[i]}" = '<' ] && { a=${SEG_TXT[i]}; b=$prev; }
      if [[ $a =~ (^|[[:space:]])(curl|wget|fetch|aria2c|http)([[:space:]]|$) ]] &&
         [[ $b =~ (^|[[:space:]])(sudo[[:space:]]+)?(sh|bash|zsh|dash|ksh|fish|python|python3|node|ruby|perl|php)([[:space:]]|$) ]]; then
        block "pipes a download straight into an interpreter — fetch, read, then run"
      fi
    fi
    prev=${SEG_TXT[i]}
  done
  return 0
}

evaluate() {
  tokenize "$1"
  pipeline_rules
  local i
  for ((i=0; i<${#SEG_TXT[@]}; i++)); do
    if [ "${SEG_SEP[i]}" = 'C' ] || [ "${SEG_SEP[i]}" = 'T' ]; then
      rules_code "${SEG_TXT[i]}" "${SEG_SEP[i]}"
    else
      rules_shell "${SEG_TXT[i]}" "${SEG_CW[i]}" "${SEG_S1[i]}" "${SEG_S2[i]}" "${SEG_LAST[i]}"
    fi
  done
  exit 0
}

# --- entry -------------------------------------------------------------------
if [ "$#" -eq 2 ] && [ "$1" = "--batch" ]; then
  [ -r "$2" ] || { echo "guard-command.sh --batch: cannot read $2" >&2; exit 1; }
  while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    ( evaluate "$line" ) >/dev/null 2>&1
    printf '%s\t%s\n' "$?" "$line"
  done <"$2"
  exit 0
fi

if [ "$#" -lt 1 ] || [ -z "${1:-}" ]; then
  echo "Blocked: command guard could not read the command (missing arg, or jq/payload problem upstream)" >&2
  exit 2
fi

evaluate "$1"
