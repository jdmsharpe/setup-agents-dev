# Claude Code — user-global instructions

@~/.claude/AGENTS.md

## Claude Code specifics (this machine)

- The Bash tool runs a **non-login, non-interactive** shell that never sources `.profile`/`.bashrc` — a tool working in the user's terminal does not mean it's on the Bash-tool PATH. Deep detail + the "why" live in auto-memory.
- On the Bash-tool PATH the shims are definitively absent: invoke `uv` as `~/.local/bin/uv`; prefix cargo/rustc/rustup calls with `. "$HOME/.cargo/env" &&`; nvm is not sourced.
- `firecrawl` (at `~/.npm-global/bin`) IS on the Bash-tool PATH — settings.json adds it; no full path needed.
- `~/.claude/settings.json` `env` block does **NOT** interpolate `${VAR}` — hardcode literal values (this is why PATH is spelled out in full). Changes need a full Claude Code restart.
- `git push` / `gh release` work non-interactively because `GH_TOKEN` is in settings.json `env` and the gh credential helper is installed. The GitHub **MCP plugin** separately needs `GITHUB_PERSONAL_ACCESS_TOKEN` (same value, different consumer) — keep both in sync on rotation.
- Playwright/Patchright → `PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64` is ambient via settings.json `env` (since 2026-07-11). Remove it once Playwright ships ubuntu26.04-x64 browser builds — an ambient override silently pins old builds.
