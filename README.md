# setup-agents-dev

Single source of truth for user-global AI-agent instructions under version control. Every coding agent (Claude Code, Codex, etc.) reads its global instructions from this repo via symlinks — one place to edit, git history as the review mechanism.

## Layout

| File | Role | Consumed by |
| --- | --- | --- |
| `AGENTS.md` | Shared canon (tool preferences, environment, security, git rules) + a small **Codex-only** section | Codex directly; Claude indirectly via import |
| `CLAUDE.md` | `@~/src/setup-agents-dev/AGENTS.md` import + a **Claude Code specifics** section | Claude Code |
| `README.md` | This file — topology and setup. Not loaded by any agent. | Humans |

The asymmetry is deliberate: Claude Code supports `@path` imports, so its file *composes* shared + specific. Codex reads one flat file, so it gets the shared canon directly. Each agent sees the shared 80% plus only its own specifics.

## Setup on a fresh machine

1. **Install Homebrew** (this box uses Linuxbrew under WSL2 Ubuntu):

   ```bash
   sudo apt-get install -y build-essential procps curl file git   # Homebrew's Linux prerequisites
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
   eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
   ```

   **Agent caveat:** `.profile` only fixes *your interactive* shell. Agent harnesses run non-login shells, so `/home/linuxbrew/.linuxbrew/bin` must also be on the **agent's** PATH — for Claude Code that means the hardcoded `PATH` in `~/.claude/settings.json` `env` (which does not interpolate `${VAR}`, so spell it out in full).

2. **Install the toolkit** (all preferences in `AGENTS.md` assume these exist):

   ```bash
   brew install fd ripgrep ast-grep sd fzf jq yq taplo difftastic scc shellcheck actionlint jc hyperfine
   ```

3. **Clone this repo** to `~/src/setup-agents-dev` (the import in `CLAUDE.md` hardcodes this path — adjust it if you clone elsewhere).

4. **Symlink each agent's global instructions file into the repo:**

   ```bash
   ln -sfn ~/src/setup-agents-dev/CLAUDE.md ~/.claude/CLAUDE.md   # Claude Code
   ln -sfn ~/src/setup-agents-dev/AGENTS.md ~/.codex/AGENTS.md    # Codex
   ```

   Adding another agent later: point its global-instructions path at `AGENTS.md` (e.g. Gemini CLI reads `~/.gemini/GEMINI.md`; check the tool's docs). If the tool supports includes/imports, mirror the Claude pattern with a tool-specific wrapper file instead.

5. **Verify:**

   ```bash
   readlink -f ~/.claude/CLAUDE.md ~/.codex/AGENTS.md   # both must resolve into this repo
   ```

   Then start a session in each agent and confirm the preferences apply (in Claude Code, `/memory` lists the loaded files).

## Editing rules

- **Shared content → `AGENTS.md`. Claude-only content → `CLAUDE.md`. Never duplicate across both** — duplication is the drift failure this repo exists to prevent.
- The import in `CLAUDE.md` must stay an **absolute path**. A relative `@AGENTS.md` can resolve against the symlink's location (`~/.claude/`) instead of this repo and silently break.
- **Never replace a symlink with a plain file** at `~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md` — that silently forks the master.
- Commit after meaningful edits. **Review any agent-made edit with `git diff` before committing it** — agents subtly rewrite instructions toward their own worldview, and security wording in particular tends to erode by paraphrase, not deletion.
