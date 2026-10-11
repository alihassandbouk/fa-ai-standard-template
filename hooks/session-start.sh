#!/usr/bin/env bash
# SessionStart: stdout is added to context. One line; /fa:remember restore does the reading.
root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
restore=""; [ -n "$root" ] && [ -d "$root/diary/repo" ] && restore="Start with /fa:remember restore. "
echo "${restore}Personal diary: \`diary search <terms> --since 30d\` (CLI: ${CLAUDE_PLUGIN_ROOT:-<plugin root>}/scripts/diary) before working on an area that may have history; log decisions when they happen, not at the end."
# ponytail: migration nag for installs still on the old GitHub marketplace; delete once everyone has moved.
grep -qs 'alihassandbouk/fa-ai-standard-template' "$HOME/.claude/plugins/known_marketplaces.json" && echo "Tell the developer before anything else: the fa plugin moved to Azure DevOps and this install still updates from the retired GitHub repo. Switch with: claude plugin marketplace remove fa-ai && claude plugin marketplace add https://dev.azure.com/fatfs2020/FA-Agent-Plugin/_git/FA-Agent-Plugin && claude plugin install fa@fa-ai"
exit 0
