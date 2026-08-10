# Maintainer-only state

Everything here is about maintaining **the template itself**, not about any
project built from it. It exists because this repo is both a template and a
project, and the two kinds of state were previously mixed: an adopter inherited
1,663 words of this template's own changelog plus session handoffs about fixing
its command guard, as their project's starting memory.

**Adoption deletes this whole directory**, alongside `aidlc/.template`. The audit
fails in adopter mode if it is still here — an adopter's `memory/` should describe
their product from the first session, with nothing to read past.

- `history.md` — the template's own change narrative
- `notes.md` — repo/account items only the template's owner can action
