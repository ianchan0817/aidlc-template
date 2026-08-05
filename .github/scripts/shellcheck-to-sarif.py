#!/usr/bin/env python3
"""Convert `shellcheck -f json1` output to SARIF 2.1.0.

Kept as a tiny local script rather than a third-party action: the whole point of
this workflow is supply-chain hygiene, so it should not pull an unpinned action
to do 40 lines of JSON reshaping.

Usage: shellcheck-to-sarif.py <shellcheck.json> <out.sarif>
"""
import json
import sys

LEVELS = {"error": "error", "warning": "warning", "info": "note", "style": "note"}


def main(src: str, dst: str) -> int:
    with open(src, encoding="utf-8") as fh:
        comments = json.load(fh).get("comments", [])

    rules: dict[str, dict] = {}
    results = []

    for c in comments:
        rule_id = f"SC{c['code']}"
        rules.setdefault(
            rule_id,
            {
                "id": rule_id,
                "name": rule_id,
                "shortDescription": {"text": c["message"]},
                "helpUri": f"https://www.shellcheck.net/wiki/{rule_id}",
                "properties": {"problem": {"severity": LEVELS.get(c["level"], "note")}},
            },
        )
        results.append(
            {
                "ruleId": rule_id,
                "level": LEVELS.get(c["level"], "note"),
                "message": {"text": c["message"]},
                "locations": [
                    {
                        "physicalLocation": {
                            "artifactLocation": {"uri": c["file"].lstrip("./")},
                            "region": {
                                "startLine": max(1, c.get("line", 1)),
                                "startColumn": max(1, c.get("column", 1)),
                            },
                        }
                    }
                ],
            }
        )

    sarif = {
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "version": "2.1.0",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "ShellCheck",
                        "informationUri": "https://www.shellcheck.net",
                        "rules": list(rules.values()),
                    }
                },
                "results": results,
            }
        ],
    }

    with open(dst, "w", encoding="utf-8") as fh:
        json.dump(sarif, fh, indent=2)

    print(f"{len(results)} finding(s) -> {dst}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(main(sys.argv[1], sys.argv[2]))
