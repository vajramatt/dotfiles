# dotfiles

![dotfiles — figlet ANSI Shadow in a TokyoNight gradient](docs/banner.svg)

My Mac terminal setup: **Ghostty** + **Starship** + **eza** + the **TokyoNight** Claude Code statusline.

> Syncing to another Mac or making changes? See **[HOWTO.md](HOWTO.md)** for how changes
> propagate (symlinked configs are instant; packages/aliases need a `bootstrap.sh` re-run).

## The HAL 9000 stuff

![The MOTD: HAL eye, live stats, a quote — and the prod tripwire in the prompt below](docs/motd.png)

*(Screenshot is staged — `dave @ discovery-one` and friends come from `docs/motd-shot.zsh`, not a real machine.)*

Every new terminal opens with a truecolor HAL 9000 eye — rendered in pure zsh with
half-block pixels (~20 ms, no image files, no figlet dependency) — beside live stats
(memory, load, battery, disk, LAN IP) and a time-of-day HAL quote. Battery and disk turn
red when low, and past 30 days of uptime the quote locks to *"Dave, my mind is going."*

The prompt is in on it too:

- a failed command turns the Starship keel into HAL's eye — `╰─◉` — with
  *"I'm afraid I can't do that, Dave"* and the exit code on the top line
- typos get the full *"I'm sorry, Dave. I'm afraid I can't do that."*
- wrangler repos show a Cloudflare badge that flips to a red **⚠ prod!** on
  main/master (visible in the screenshot above)
- commands running ≥30s send a macOS notification: *"Processing complete, Dave."*
- past prompts collapse to a single `☸ cmd` line, so scrollback stays clean

Escape hatches: `export MOTD_HAL=0` (plain greeting) and `export TRANSIENT_PROMPT=0`
(keep full prompts in scrollback). Full-size eye: `~/.config/hal9000.sh 19`.

## One-command setup on a new Mac

```bash
git clone https://github.com/vajramatt/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
```

Then open a new terminal (or `exec zsh`).

## What `bootstrap.sh` does

1. Installs **Homebrew** if it's missing.
2. `brew install starship jq eza zsh-autosuggestions zsh-syntax-highlighting` and `brew install --cask ghostty font-jetbrains-mono-nerd-font`.
3. Symlinks the configs into place (backing up anything already there to `*.bak.<timestamp>`):
   - `~/.config/starship.toml` → two-line prompt: `╭─` directory + git branch/status + runtime versions/clock, then the `╰─☸` keel
   - `~/.config/ghostty/config` → TokyoNight Night theme + `JetBrainsMono Nerd Font Mono`
   - `~/.config/motd.sh` → TokyoNight MOTD on every new terminal: compact HAL 9000 eye beside user@host, date/uptime, memory/load/battery, disk/LAN IP, and a time-aware HAL quote; low battery/disk turn red (`export MOTD_HAL=0` for the plain greeting)
   - `~/.config/hal.zsh` → HAL zsh extras: transient prompt (old prompts collapse to `☸ cmd`; `export TRANSIENT_PROMPT=0` to disable), command-not-found in HAL's voice, macOS notification when a command runs ≥30s
   - `~/.claude/hooks/statusline.sh` → TokyoNight statusline for Claude Code
4. Merges the `statusLine` block into `~/.claude/settings.json` (rest of the file is left untouched; a `.bak` is kept).
5. Ensures `~/.zshrc` sources **zsh-autosuggestions** (fish-style ghost text), `eval "$(starship init zsh)"`, the **eza** aliases (`ls`/`la`/`ll`/`lt`), the **MOTD** greeting, and **zsh-syntax-highlighting** (sourced last, as it requires).

It's **idempotent** — safe to re-run.

## Layout

```
config/
  starship.toml        # Starship prompt
  ghostty/config       # Ghostty terminal
  motd.sh              # MOTD greeting (sourced from ~/.zshrc)
  hal9000.sh           # truecolor HAL 9000 eye (zsh-rendered; sized via arg, used by motd.sh)
  hal.zsh              # transient prompt + HAL command-not-found + long-command notifications
claude/
  hooks/statusline.sh  # TokyoNight statusline
docs/
  banner.mjs           # regenerates banner.svg (figlet + TokyoNight gradient, zero deps)
  banner.svg           # the README banner
  motd-shot.zsh        # captures motd.sh with staged demo data -> motd.ansi
  motd-shot.mjs        # renders motd.ansi -> motd.png via headless Chrome
  motd.png             # the README screenshot (staged: dave@discovery-one, fake stats)
bootstrap.sh
```

## Editing

Configs are **symlinked**, so editing a file under `~/.config` / `~/.claude/hooks` edits the
repo copy directly. Commit and push to sync:

```bash
cd ~/dotfiles && git add -A && git commit -m "tweak config" && git push
```

## Credits

- Statusline: [vajramatt/claude-tokyonight-statusline](https://github.com/vajramatt/claude-tokyonight-statusline)
- [Starship](https://starship.rs) · [Ghostty](https://ghostty.org) · [TokyoNight](https://github.com/folke/tokyonight.nvim)
