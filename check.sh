#!/usr/bin/env bash
# Drift guards between the instruction files and the toolkit manifest.
# Run by CI on every push/PR; run locally after editing AGENTS.md, CLAUDE.md,
# or Brewfile. Uses classic grep/sed/awk so it works on bare CI runners.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

fail=0
err() {
  printf 'FAIL: %s\n' "$1" >&2
  fail=1
}

# Binary name <-> Homebrew formula name, where they differ.
declare -A formula_of=([rg]=ripgrep [difft]=difftastic)
declare -A binary_of=([ripgrep]=rg [difftastic]=difft)

# 1. CLAUDE.md must import the shared canon through the ~/.claude/AGENTS.md
#    indirection — without this line the canon silently stops loading.
grep -qxF '@~/.claude/AGENTS.md' CLAUDE.md ||
  err "CLAUDE.md lost its '@~/.claude/AGENTS.md' import line"

# 2. Every tool the AGENTS.md decision tree recommends must be in the Brewfile.
#    The recommended tool is the first backticked token of each bullet.
# shellcheck disable=SC2016  # backticks in the sed pattern are literal markdown, not expansion
tree_tools="$(awk '/^### Quick decision tree$/{f=1; next} /^### /{f=0} f && /^- /' AGENTS.md |
  grep '`' | sed -E 's/^[^`]*`([a-zA-Z0-9_-]+).*/\1/' | sort -u)"
if [ -z "$tree_tools" ]; then
  err "could not extract any tools from AGENTS.md's 'Quick decision tree' section"
fi
for tool in $tree_tools; do
  formula="${formula_of[$tool]:-$tool}"
  grep -q "^brew \"$formula\"" Brewfile ||
    err "decision-tree tool '$tool' (formula '$formula') is missing from Brewfile"
done

# 3. Every Brewfile formula must still be mentioned in AGENTS.md — a tool
#    dropped from the canon should be dropped from the manifest too.
while IFS= read -r formula; do
  binary="${binary_of[$formula]:-$formula}"
  grep -q "\`$binary" AGENTS.md ||
    err "Brewfile formula '$formula' (binary '$binary') is no longer mentioned in AGENTS.md"
done < <(sed -nE 's/^brew "([^"]+)".*/\1/p' Brewfile)

if [ "$fail" -eq 0 ]; then
  printf 'check.sh: all drift guards pass (%d decision-tree tools verified)\n' "$(printf '%s\n' "$tree_tools" | wc -l)"
fi
exit "$fail"
