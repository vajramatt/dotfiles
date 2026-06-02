# dotfiles

My Mac terminal setup: **Ghostty** + **Starship** + **eza** + the **TokyoNight** Claude Code statusline.

> Syncing to another Mac or making changes? See **[HOWTO.md](HOWTO.md)** for how changes
> propagate (symlinked configs are instant; packages/aliases need a `bootstrap.sh` re-run).

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
   - `~/.claude/hooks/statusline.sh` → TokyoNight statusline for Claude Code
4. Merges the `statusLine` block into `~/.claude/settings.json` (rest of the file is left untouched; a `.bak` is kept).
5. Ensures `~/.zshrc` sources **zsh-autosuggestions** (fish-style ghost text), `eval "$(starship init zsh)"`, the **eza** aliases (`ls`/`la`/`ll`/`lt`), and **zsh-syntax-highlighting** (sourced last, as it requires).

It's **idempotent** — safe to re-run.

## Layout

```
config/
  starship.toml        # Starship prompt
  ghostty/config       # Ghostty terminal
claude/
  hooks/statusline.sh  # TokyoNight statusline
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
