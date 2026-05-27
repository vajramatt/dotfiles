# dotfiles

My Mac terminal setup: **Ghostty** + **Starship** + the **TokyoNight** Claude Code statusline.

## One-command setup on a new Mac

```bash
git clone https://github.com/vajramatt/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
```

Then open a new terminal (or `exec zsh`).

## What `bootstrap.sh` does

1. Installs **Homebrew** if it's missing.
2. `brew install starship jq` and `brew install --cask ghostty`.
3. Symlinks the configs into place (backing up anything already there to `*.bak.<timestamp>`):
   - `~/.config/starship.toml` → minimal prompt: working directory then `$`
   - `~/.config/ghostty/config` → TokyoNight Night theme
   - `~/.claude/hooks/statusline.sh` → TokyoNight statusline for Claude Code
4. Merges the `statusLine` block into `~/.claude/settings.json` (rest of the file is left untouched; a `.bak` is kept).
5. Ensures `eval "$(starship init zsh)"` is in `~/.zshrc`.

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
