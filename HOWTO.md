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

> ⚠️ **The flip side of idempotence:** `bootstrap.sh` will **not** update an alias / `source` line
> whose marker is *already* in `~/.zshrc`. So if the change you're syncing **edited an existing**
> `append_once` block (e.g. added a flag to the `ls` alias) rather than adding a brand-new one,
> `git pull` + `./bootstrap.sh` does **nothing** on this machine — you must **hand-edit `~/.zshrc`**
> to match. See [Changing an existing alias](#changing-an-existing-alias) below.

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

<a name="changing-an-existing-alias"></a>
- **Changing an *existing* alias / `source` line / `append_once` block** — this is the sharp edge,
  and it bites differently from *adding* one. Editing the block in `bootstrap.sh` only helps
  **fresh** machines. On any machine that has already been bootstrapped, the block's marker is
  *already* in `~/.zshrc`, so `append_once` sees it and **skips** — re-running `bootstrap.sh` will
  **not** rewrite the line, and `git pull` can't either (`~/.zshrc` isn't a symlink). So editing an
  existing block is always a **two-place change**:
  1. the `append_once` block in `bootstrap.sh` — so **future** machines get it, and so the repo
     stays the source of truth;
  2. the live `~/.zshrc` **by hand** on **every already-bootstrapped machine** — so they actually
     pick it up.
  - Worked example: adding `--icons` to the `ls`/`la`/`lt` aliases (commit `f641992`) had to touch
    both `bootstrap.sh` *and* each machine's `~/.zshrc` directly, for exactly this reason. Updating
    only `bootstrap.sh` would have silently no-op'd on machines that were already set up.

```bash
cd ~/code/dotfiles && git add -A && git commit -m "describe change" && git push
```

## Notes for an AI agent working in this repo

- **Editing a `~/.config/...` file edits this repo** — they're symlinks. Treat any change there
  as a repo change: commit it.
- **Before assuming an alias/tool exists on a fresh machine**, check `bootstrap.sh`, not just the
  configs. A config can reference a font/glyph that only `bootstrap.sh` installs.
- **Editing an existing `append_once` block ≠ propagating it.** The marker-gate means re-running
  `bootstrap.sh` *skips* any block already present in `~/.zshrc`. A content change to an existing
  alias/`source` line must therefore be applied to the live `~/.zshrc` **by hand** on each
  bootstrapped machine — updating only `bootstrap.sh` silently no-ops for them. (Adding a *new*
  block with a *new* marker is fine — that's what bootstrap is for.)
- **Font names matter:** Ghostty needs the exact family name it reports from
  `ghostty +list-fonts` (currently `JetBrainsMono Nerd Font Mono`), not the cask name.
- **Verify after editing** `starship.toml` by rendering, not by `starship config` (which opens an
  editor): `cd <a-git-repo> && starship prompt`.
- Keep this repo and the README in sync when the bootstrap package list or steps change.

## Current setup at a glance

- **Shell:** zsh + zsh-autosuggestions + zsh-syntax-highlighting
- **Prompt:** Starship, TokyoNight palette, two-line frame ending in the `╰─☸` keel; on failure the keel becomes HAL's eye (`╰─◉`) with the exit code quoted on the top line; a `custom.cloudflare` badge marks wrangler repos (red `⚠ prod!` on main/master); battery appears right-side only when ≤20%
- **HAL zsh extras:** `config/hal.zsh` (symlinked, sourced from `~/.zshrc` after starship init) — transient prompt collapsing past prompts to `☸ cmd` (`export TRANSIENT_PROMPT=0` to disable), command-not-found in HAL's voice, macOS notification for commands ≥30s
- **Terminal:** Ghostty, TokyoNight Night, `JetBrainsMono Nerd Font Mono` @ 14pt
- **`ls`:** aliased to `eza` (`ls`/`la`/`ll`/`lt`) — icons, git status, dir-grouping
- **MOTD:** `config/motd.sh` (symlinked to `~/.config/motd.sh`, sourced from `~/.zshrc`) — compact HAL 9000 eye (`config/hal9000.sh`) beside user@host, date/uptime, memory/load/battery, disk/LAN IP, and a time-of-day HAL quote; battery ≤20% (discharging) and disk <50G render red, uptime >30d changes the quote to "Dave, my mind is going" — `export MOTD_HAL=0` reverts to the plain greeting, `~/.config/hal9000.sh` renders the full-size eye
- **Claude Code:** TokyoNight statusline
