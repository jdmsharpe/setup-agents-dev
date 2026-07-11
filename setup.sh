#!/usr/bin/env bash
# Point each agent's global-instructions path at this repo's files (README step 4).
# Idempotent: re-running with correct links is a no-op. Refuses to replace any
# existing configuration it didn't create, and reports every conflict in one run.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
for f in AGENTS.md CLAUDE.md; do
  if [ ! -f "$repo_dir/$f" ]; then
    printf 'Missing %s — this script must live inside the setup-agents-dev clone.\n' "$repo_dir/$f" >&2
    exit 1
  fi
done

targets=("$repo_dir/CLAUDE.md" "$repo_dir/AGENTS.md" "$repo_dir/AGENTS.md")
links=("$HOME/.claude/CLAUDE.md" "$HOME/.claude/AGENTS.md" "$HOME/.codex/AGENTS.md")

conflicts=0
for i in "${!links[@]}"; do
  if { [ -e "${links[$i]}" ] || [ -L "${links[$i]}" ]; } &&
     { [ ! -L "${links[$i]}" ] || [ "$(readlink -f "${links[$i]}")" != "$(readlink -f "${targets[$i]}")" ]; }; then
    if [ -L "${links[$i]}" ] && [ ! -e "${links[$i]}" ]; then
      printf 'Refusing to replace dangling symlink (safe to rm): %s -> %s\n' "${links[$i]}" "$(readlink "${links[$i]}")" >&2
    else
      printf 'Refusing to replace existing configuration: %s\n' "${links[$i]}" >&2
    fi
    conflicts=$((conflicts + 1))
  fi
done
if [ "$conflicts" -gt 0 ]; then
  printf 'Review/merge the path(s) above into this repo, then re-run.\n' >&2
  exit 1
fi

mkdir -p "$HOME/.claude" "$HOME/.codex"
ln -sfn "${targets[0]}" "${links[0]}"   # Claude Code wrapper
ln -sfn "${targets[1]}" "${links[1]}"   # Claude Code import
ln -sfn "${targets[2]}" "${links[2]}"   # Codex

for link in "${links[@]}"; do
  printf '%s -> %s\n' "$link" "$(readlink -f "$link")"
done
