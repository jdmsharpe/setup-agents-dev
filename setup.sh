#!/usr/bin/env bash
# Point each agent's global-instructions path at this repo's files (README step 4).
# Idempotent: re-running with correct links is a no-op. Refuses to replace any
# existing configuration it didn't create, and reports every conflict in one run.
#   --check   verify-only: report each link's state and exit 1 on any problem,
#             without creating or changing anything.
set -euo pipefail

check_only=0
case "${1-}" in
  --check) check_only=1 ;;
  '') ;;
  *) printf 'Usage: %s [--check]\n' "${0##*/}" >&2; exit 2 ;;
esac

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
for f in AGENTS.md CLAUDE.md; do
  if [ ! -f "$repo_dir/$f" ]; then
    printf 'Missing %s — this script must live inside the setup-agents-dev clone.\n' "$repo_dir/$f" >&2
    exit 1
  fi
done

targets=("$repo_dir/CLAUDE.md" "$repo_dir/AGENTS.md" "$repo_dir/AGENTS.md")
links=("$HOME/.claude/CLAUDE.md" "$HOME/.claude/AGENTS.md" "$HOME/.codex/AGENTS.md")

# ok: correct symlink | absent: nothing there (installable)
# dangling: symlink to nowhere | conflict: plain file or symlink elsewhere
state_of() {
  if [ -L "$1" ] && [ -e "$1" ] && [ "$(readlink -f "$1")" = "$(readlink -f "$2")" ]; then
    printf 'ok'
  elif [ ! -e "$1" ] && [ ! -L "$1" ]; then
    printf 'absent'
  elif [ -L "$1" ] && [ ! -e "$1" ]; then
    printf 'dangling'
  else
    printf 'conflict'
  fi
}

problems=0
for i in "${!links[@]}"; do
  link="${links[$i]}"
  state="$(state_of "$link" "${targets[$i]}")"

  if [ "$check_only" -eq 1 ]; then
    if [ "$state" = ok ]; then
      printf 'ok: %s -> %s\n' "$link" "$(readlink -f "$link")"
    else
      printf 'PROBLEM (%s): %s\n' "$state" "$link" >&2
      problems=$((problems + 1))
    fi
    continue
  fi

  case "$state" in
    dangling)
      printf 'Refusing to replace dangling symlink (safe to rm): %s -> %s\n' "$link" "$(readlink "$link")" >&2
      problems=$((problems + 1)) ;;
    conflict)
      printf 'Refusing to replace existing configuration: %s\n' "$link" >&2
      problems=$((problems + 1)) ;;
  esac
done

if [ "$check_only" -eq 1 ]; then
  if [ "$problems" -gt 0 ]; then
    printf '%d link(s) need attention — resolve any conflicts, then run setup.sh to fix.\n' "$problems" >&2
    exit 1
  fi
  exit 0
fi

if [ "$problems" -gt 0 ]; then
  printf 'Review/merge the path(s) above into this repo, then re-run.\n' >&2
  exit 1
fi

mkdir -p "$HOME/.claude" "$HOME/.codex"
ln -sfn "${targets[0]}" "${links[0]}"   # Claude Code wrapper
ln -sfn "${targets[1]}" "${links[1]}"   # Claude Code import (CLAUDE.md resolves through this)
ln -sfn "${targets[2]}" "${links[2]}"   # Codex

for link in "${links[@]}"; do
  printf '%s -> %s\n' "$link" "$(readlink -f "$link")"
done
