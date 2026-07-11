# setup-agents-dev

Single source of truth for user-global AI-agent instructions under version control. Every coding agent (Claude Code, Codex, etc.) reads its global instructions from this repo via symlinks — one place to edit, git history as the review mechanism.

## Layout

| File | Role | Consumed by |
| --- | --- | --- |
| `AGENTS.md` | Shared canon (tool preferences, environment, security, git rules) + a small **Codex-only** section | Codex directly; Claude indirectly via import |
| `CLAUDE.md` | `@~/.claude/AGENTS.md` import + a **Claude Code specifics** section | Claude Code |
| `README.md` | This file — topology and setup. Not loaded by any agent. | Humans |
| `setup.sh` | Idempotent symlink installer (setup step 4) | Humans |

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

3. **Clone this repo** wherever you keep source repositories, then enter the clone:

   ```bash
   git clone https://github.com/jdmsharpe/setup-agents-dev.git
   cd setup-agents-dev
   ```

4. **Point each agent's global instructions path at the files in this repo:**

   **Existing configuration:** `setup.sh` refuses to replace `~/.claude/CLAUDE.md`, `~/.claude/AGENTS.md`, or `~/.codex/AGENTS.md` when it is a plain file or points elsewhere, and reports every conflict in one run. Review and merge the reported contents into this repo before continuing; back them up first if you are unsure.

   ```bash
   ./setup.sh
   ```

   The script locates its own repo (so it can be run from anywhere), links `~/.claude/CLAUDE.md` → `CLAUDE.md` and `~/.claude/AGENTS.md` + `~/.codex/AGENTS.md` → `AGENTS.md`, then prints where each link resolves. Re-running when the links are already correct is a no-op.

   Adding another agent later: point its global-instructions path at `AGENTS.md` (e.g. Gemini CLI reads `~/.gemini/GEMINI.md`; check the tool's docs). If the tool supports includes/imports, mirror the Claude pattern with a tool-specific wrapper file instead.

5. **Verify:** `setup.sh` prints where each link resolves — all three must point into this repo. Then start a session in each agent and confirm the preferences apply (in Claude Code, `/memory` lists the loaded files).

## Editing rules

- **Shared content → `AGENTS.md`. Claude-only content → `CLAUDE.md`. Never duplicate across both** — duplication is the drift failure this repo exists to prevent.
- Keep the `@~/.claude/AGENTS.md` import in `CLAUDE.md` and both Claude-side symlinks `setup.sh` creates. The import is home-anchored (a documented Claude Code form), so it resolves identically wherever this repo is cloned; the companion `~/.claude/AGENTS.md` symlink is the indirection point it resolves through — without it the shared canon silently stops loading.
- **Never replace a symlink with a plain file** at `~/.claude/CLAUDE.md`, `~/.claude/AGENTS.md`, or `~/.codex/AGENTS.md` — that silently forks the master.
- Commit after meaningful edits. **Review any agent-made edit with `git diff` before committing it** — agents subtly rewrite instructions toward their own worldview, and security wording in particular tends to erode by paraphrase, not deletion.
