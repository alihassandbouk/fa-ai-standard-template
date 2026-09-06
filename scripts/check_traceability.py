#!/usr/bin/env python3
"""
check_traceability.py

Function: Enforces Gate C mechanically. Maps requirement ID -> test -> pass/fail.
Fails the build (non-zero exit) if any Must/MVP requirement in specs/ has no
passing, linked test.

TODO for this project:
  1. Parse requirement IDs out of specs/*.md
  2. Parse test files for a linked requirement ID (e.g. a marker/tag/docstring
     convention agreed in code-standards.md)
  3. Run the test suite (or read its last results)
  4. For every Must/MVP requirement with no passing linked test, print it and
     exit non-zero.

A requirement ID mentioned in a comment ("Traceable to HLR-042") does NOT
count as traceability. Only a passing, linked test does.
"""

import sys


def main() -> int:
    # TODO: implement per project.
    print("check_traceability.py: not yet implemented for this project.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
