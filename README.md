# setup-agents-dev

Single source of truth for user-global AI-agent instructions under version control. Every coding agent (Claude Code, Codex, etc.) reads its global instructions from this repo via symlinks — one place to edit, git history as the review mechanism.

## Layout

| File | Role | Consumed by |
| --- | --- | --- |
| `AGENTS.md` | Shared canon (tool preferences, environment, security, git rules) + a small **Codex-only** section | Codex directly; Claude indirectly via import |
| `CLAUDE.md` | `@~/.claude/AGENTS.md` import + a **Claude Code specifics** section | Claude Code |
| `Brewfile` | The toolkit `AGENTS.md`'s preferences assume — `brew bundle` installs it, `brew bundle check --verbose` audits an existing machine | Humans; CI |
| `setup.sh` | Idempotent symlink installer (setup step 4); `--check` verifies without changing anything | Humans |
| `check.sh` | Drift guards: import line intact, decision-tree tools ⊆ `Brewfile`, `Brewfile` ⊆ `AGENTS.md` | CI; humans |
| `.github/workflows/ci.yml` | shellcheck + actionlint + drift guards on every push/PR | CI |
| `README.md` | This file — topology and setup. Not loaded by any agent. | Humans |

The asymmetry is deliberate: Claude Code supports `@path` imports, so its file *composes* shared + specific. Codex reads one flat file, so it gets the shared canon directly. Each agent sees the shared 80% plus only its own specifics.

## Setup on a fresh machine

1. **Install Homebrew.** Commands below are for Linux/WSL2, where Homebrew installs as Linuxbrew (the `apt-get` line is its Linux prerequisites); on macOS follow [brew.sh](https://brew.sh) and skip the apt step:

   ```bash
   sudo apt-get install -y build-essential procps curl file git
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
   eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
   ```

   **Agent caveat:** `.profile` only fixes *your interactive* shell. Agent harnesses run non-login shells, so Homebrew's bin directory must also be on the **agent's** PATH — for Claude Code that means the hardcoded `PATH` in `~/.claude/settings.json` `env` (which does not interpolate `${VAR}`, so spell it out in full).

2. **Clone this repo** wherever you keep source repositories, then enter the clone:

   ```bash
   git clone https://github.com/jdmsharpe/setup-agents-dev.git
   cd setup-agents-dev
   ```

3. **Install the toolkit** (all preferences in `AGENTS.md` assume these exist):

   ```bash
   brew bundle
   ```

   On a machine that already has tools installed, `brew bundle check --verbose` lists what's missing without installing anything.

4. **Point each agent's global instructions path at the files in this repo:**

   **Existing configuration:** `setup.sh` refuses to replace `~/.claude/CLAUDE.md`, `~/.claude/AGENTS.md`, or `~/.codex/AGENTS.md` when it is a plain file or points elsewhere, and reports every conflict in one run. Review and merge the reported contents into this repo before continuing; back them up first if you are unsure.

   ```bash
   ./setup.sh
   ```

   The script locates its own repo (so it can be run from anywhere), links `~/.claude/CLAUDE.md` → `CLAUDE.md` and `~/.claude/AGENTS.md` + `~/.codex/AGENTS.md` → `AGENTS.md`, then prints where each link resolves. Re-running when the links are already correct is a no-op.

   Adding another agent later: point its global-instructions path at `AGENTS.md` (e.g. Gemini CLI reads `~/.gemini/GEMINI.md`; check the tool's docs). If the tool supports includes/imports, mirror the Claude pattern with a tool-specific wrapper file instead.

5. **Verify:** `./setup.sh --check` reports each link's state and exits non-zero on any problem, without changing anything — use it any time to audit the topology. Then start a session in each agent and confirm the preferences apply (in Claude Code, `/memory` lists the loaded files).

## Editing rules

- **Shared content → `AGENTS.md`. Claude-only content → `CLAUDE.md`. Never duplicate across both** — duplication is the drift failure this repo exists to prevent.
- Keep the `@~/.claude/AGENTS.md` import in `CLAUDE.md` and both Claude-side symlinks `setup.sh` creates. The import is home-anchored (a documented Claude Code form), so it resolves identically wherever this repo is cloned; the companion `~/.claude/AGENTS.md` symlink is the indirection point it resolves through — without it the shared canon silently stops loading.
- **Never replace a symlink with a plain file** at `~/.claude/CLAUDE.md`, `~/.claude/AGENTS.md`, or `~/.codex/AGENTS.md` — that silently forks the master.
- Adding or removing a tool preference means touching **both** `AGENTS.md` and `Brewfile` — `./check.sh` fails when they drift apart (or when `CLAUDE.md` loses its import line). CI runs it on every push; run it locally after editing either file.
- Commit after meaningful edits. **Review any agent-made edit with `git diff` before committing it** — agents subtly rewrite instructions toward their own worldview, and security wording in particular tends to erode by paraphrase, not deletion.

## License

MIT — see [LICENSE](LICENSE).
