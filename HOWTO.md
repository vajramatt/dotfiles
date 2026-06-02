# HOWTO — how changes flow, and how to sync Macs

This repo is the **source of truth** for the terminal setup. The trick to working in it
is understanding that changes reach a machine by **two different mechanisms**, and only one
of them is automatic.

## The mental model: two kinds of change

| Kind | Examples | How it reaches a Mac | Re-run `bootstrap.sh`? |
|---|---|---|---|
| **Symlinked config** | `config/starship.toml`, `config/ghostty/config`, `claude/hooks/statusline.sh` | The file at `~/.config/...` is a **symlink** into this repo. A `git pull` updates the repo file, so the live config updates **instantly**. | **No** |
| **Bootstrap-applied** | installed packages (`eza`, fonts, brew formulae), lines appended to `~/.zshrc` (aliases, plugin `source` lines) | Applied **once** by `bootstrap.sh` — a `brew install` or an `append_once` into `~/.zshrc`. These are **not** symlinks, so pulling new code does nothing until the script runs. | **Yes** |

> Rule of thumb: **if it lives under `config/` it's a symlink (instant). If it's a `brew install`
> or an `append_once` in `bootstrap.sh`, it needs a bootstrap re-run.**

## Sync the latest to another Mac

```bash
cd ~/code/dotfiles      # wherever the clone lives on that machine
git pull
./bootstrap.sh          # installs any new packages/fonts, appends any new aliases
exec zsh                # reload the shell
# then reload Ghostty:  Cmd+Shift+,   (or quit + reopen) to pick up font changes
```

`bootstrap.sh` is **idempotent**: existing symlinks are skipped, `append_once` only writes a
line if its marker isn't already in `~/.zshrc`, and `brew install` no-ops when a package is
present. Re-running it is always safe.

## Making a change here (and what it requires downstream)

- **Tweaking a symlinked config** (prompt, terminal, statusline): just edit the file under
  `config/` (or via its `~/.config` symlink — same file), commit, push. Other Macs get it on
  `git pull`, no bootstrap needed.

- **Adding a CLI tool / font:** add it to the `brew install` line (or a `brew install --cask`)
  in `bootstrap.sh`. Downstream Macs need a **bootstrap re-run**.

- **Adding a shell alias / env var / `source` line:** add it via an `append_once 'marker' 'line'`
  in `bootstrap.sh` (see the existing eza/starship/plugin blocks). The marker is a unique string
  grepped against `~/.zshrc` so it's only added once. Downstream Macs need a **bootstrap re-run**.
  - ⚠️ `~/.zshrc` itself is **not** in this repo — it's a normal file that `bootstrap.sh` appends
    to. The repo's record of those aliases *is* the `append_once` call. Don't expect to find the
    aliases as a tracked file.
  - ⚠️ `zsh-syntax-highlighting` must be the **last** thing sourced in `~/.zshrc`. When adding new
    `append_once` blocks, add them **before** the syntax-highlighting line in the script.

```bash
cd ~/code/dotfiles && git add -A && git commit -m "describe change" && git push
```

## Notes for an AI agent working in this repo

- **Editing a `~/.config/...` file edits this repo** — they're symlinks. Treat any change there
  as a repo change: commit it.
- **Before assuming an alias/tool exists on a fresh machine**, check `bootstrap.sh`, not just the
  configs. A config can reference a font/glyph that only `bootstrap.sh` installs.
- **Font names matter:** Ghostty needs the exact family name it reports from
  `ghostty +list-fonts` (currently `JetBrainsMono Nerd Font Mono`), not the cask name.
- **Verify after editing** `starship.toml` by rendering, not by `starship config` (which opens an
  editor): `cd <a-git-repo> && starship prompt`.
- Keep this repo and the README in sync when the bootstrap package list or steps change.

## Current setup at a glance

- **Shell:** zsh + zsh-autosuggestions + zsh-syntax-highlighting
- **Prompt:** Starship, TokyoNight palette, two-line frame ending in the `╰─☸` keel
- **Terminal:** Ghostty, TokyoNight Night, `JetBrainsMono Nerd Font Mono` @ 14pt
- **`ls`:** aliased to `eza` (`ls`/`la`/`ll`/`lt`) — icons, git status, dir-grouping
- **Claude Code:** TokyoNight statusline
