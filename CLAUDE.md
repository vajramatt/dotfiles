# dotfiles — house rules

Matt's Mac terminal setup — **Ghostty + Starship + eza + the Ghostwheel (Amber) MOTD + the
TokyoNight Claude Code statusline**. This repo is the **source of truth**; `bootstrap.sh`
symlinks the configs into place. Human docs: `README.md` (what it is) and **`HOWTO.md`** (how
changes propagate) — read HOWTO before changing anything non-trivial.

## This repo is PUBLIC — screen before every push

`github.com/vajramatt/dotfiles` is public from commit one. Nothing risky goes in it:
**no secrets, tokens, API keys, real hostnames, LAN IPs, work/Clevyr details, or
machine-specific identifiers.** Before committing, scan the diff for anything that shouldn't
be in a public repo.

- The README screenshots (`docs/motd.png`, banner) are **staged on purpose** — rendered against a
  throwaway `$HOME` (`matthew @ amber`, a fake `chainproof-ledger` repo) via `docs/motd-shot.zsh`,
  not a real machine. Keep them staged; never regenerate them from a real session (it would bake
  in real hostnames/paths/stats). `docs/motd.ansi` is a build intermediate and is gitignored.

## Editing a symlinked config edits your LIVE machine, instantly

The files under `config/` and `claude/hooks/` are symlinked into `~/.config/…` and
`~/.claude/hooks/…` (see the `link()` calls in `bootstrap.sh`). Editing the repo file **is**
editing the running config — no deploy step, no re-source needed for most of them. So:

- Changes take effect immediately (open a new shell / reload Ghostty with `Cmd+Shift+,` for font
  or terminal changes). Test in a real terminal before committing.
- Treat an edit here as a change to your live environment, not a sandbox.

## Two mechanisms — know which one your change needs (see HOWTO.md)

| Kind | Examples | Reaches a Mac by | Bootstrap re-run? |
|---|---|---|---|
| **Symlinked config** | `config/starship.toml`, `config/ghostty/config`, `config/motd.sh`, `config/hal.zsh`, `claude/hooks/statusline.sh` | `git pull` updates the symlink target → **instant** | No |
| **Bootstrap-applied** | brew packages/fonts, `append_once` lines in `~/.zshrc` (aliases, plugin `source` lines) | Applied once by `bootstrap.sh` | **Yes** |

- `~/.zshrc` is **not** tracked here — the repo's record of those aliases is the `append_once`
  call in `bootstrap.sh`. Don't look for the aliases as a committed file.
- **`zsh-syntax-highlighting` must be sourced last.** New `append_once` blocks go **before** that
  line in `bootstrap.sh`.
- The sharp edge: editing an **existing** `append_once` block only helps fresh machines — already-
  bootstrapped Macs have the marker in `~/.zshrc` and won't be rewritten. Hand-edit `~/.zshrc`
  there. HOWTO.md § "Changing an existing alias" covers this.
- `bootstrap.sh` is **idempotent** — safe to re-run; existing files are backed up to `*.bak.*`
  (gitignored) before linking. Keep it idempotent.

## The Claude statusline is shared with a standalone repo — keep them in sync

`claude/hooks/statusline.sh` is **byte-identical** to `statusline.sh` in
`~/code/claude-tokyonight-statusline` (the public standalone distributable). They are two homes
for the same artifact. If you change one, mirror the change to the other in the same session, or
they drift.

## Git identity

Commit as the GitHub **noreply** identity —
`Matthew Williamson <220089294+vajramatt@users.noreply.github.com>` (already the repo's local
config). Never a personal email; this is a public repo. `bootstrap.sh` also disables Claude Code's
git attribution, so **no `Co-Authored-By` trailer** in commits here. Don't commit without Matt
asking.

## Voice

The resident intelligence is **Ghostwheel** ("Ghost") — Merlin's construct from Zelazny's
*Chronicles of Amber*. MOTD/prompt copy stays in that world (the Pattern, Shadow, Tir-na Nog'th,
Kolvir, Trumps), spare and hand-written — no random-wisdom generators. New greeting lines rotate
*daily* (never flicker per-shell). Keep the escape hatches working: `MOTD_EMBLEM=0` (plain
greeting) and `TRANSIENT_PROMPT=0` (keep full prompts in scrollback).
