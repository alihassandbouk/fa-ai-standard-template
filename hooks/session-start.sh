#!/usr/bin/env bash
# SessionStart: stdout is added to context. One line; /fa:remember restore does the reading.
root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
restore=""; [ -n "$root" ] && [ -d "$root/diary/repo" ] && restore="Start with /fa:remember restore. "
echo "${restore}Personal diary: \`diary search <terms> --since 30d\` (CLI: ${CLAUDE_PLUGIN_ROOT:-<plugin root>}/scripts/diary) before working on an area that may have history; log decisions when they happen, not at the end."
