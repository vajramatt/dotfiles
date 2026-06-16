#!/usr/bin/env zsh
# Stage the README screenshot — runs the REAL motd.sh but shadows every system
# probe with fiction (matthew @ amber, 10.0.0.42, chainproof-ledger), and points
# $HOME at a throwaway dir, so the image leaks nothing about a real machine.
# See HOWTO.md.
#
#   zsh docs/motd-shot.zsh          # writes docs/motd.ansi
#   node docs/motd-shot.mjs         # then renders docs/motd.png via headless Chrome
set -euo pipefail
REPO_DIR="${0:A:h:h}"

capture() {
  # zsh resolves functions before external commands, so these shadow the real probes.
  USER=matthew
  hostname() { echo "amber" }
  sysctl() {
    case "$2" in
      kern.boottime)            echo "{ sec = $(( $(command date +%s) - (3*86400 + 2*3600) )), usec = 0 } Mon Jan  1 00:00:00 2001" ;;
      hw.memsize)               echo 34359738368 ;;        # 32G
      vm.loadavg)               echo "{ 1.24 1.18 1.07 }" ;;
      machdep.cpu.brand_string) echo "Apple M3" ;;
    esac
  }
  sw_vers()  { echo "26.0" }                               # -productVersion (staged)
  df() {
    case "$1" in
      -h) printf '%s\n%s\n' "Filesystem Size Used Avail Cap Mounted" "/dev/disk3s5 1.8Ti 600Gi 1.2Ti 33% /" ;;
      -g) printf '%s\n%s\n' "Filesystem 1G-blocks Used Available Cap Mounted" "/dev/disk3s5 1843 614 1228 33% /" ;;
    esac
  }
  vm_stat() {
    print -l "Mach Virtual Memory Statistics: (page size of 16384 bytes)" \
             "Pages active:                            600000." \
             "Pages wired down:                        200000." \
             "Pages occupied by compressor:            117504."   # => 14/32G
  }
  pmset()    { echo "Now drawing from 'AC Power' -InternalBattery-0 95%; charged; present: true" }
  route()    { echo "   interface: en0" }
  ipconfig() { echo "10.0.0.42" }
  date() {
    case "${1:-}" in
      +%s) command date +%s ;;
      +%H) echo "09" ;;                                    # morning -> "Good morning, Matthew."
      +%j) echo "107" ;;                                   # day 107 -> the "Amber is the one true city" texture line
      *)   echo "Thu 17 Apr, 09:32" ;;
    esac
  }

  # Point $HOME at a throwaway dir so motd.sh reads a staged emblem + a set Shadow,
  # and never touches the real ~/.amber or ~/.config.
  local STAGE; STAGE=$(mktemp -d)
  mkdir -p "$STAGE/.amber" "$STAGE/.config"
  ln -s "$REPO_DIR/config/ghostwheel_amber.ansi" "$STAGE/.config/ghostwheel_amber.ansi"
  print -r -- "ship the chainproof ledger spec" > "$STAGE/.amber/shadow"
  local OLD_HOME=$HOME
  HOME=$STAGE

  echo "Last login: Thu Apr 17 09:31:07 on ttys002"
  source "$REPO_DIR/config/motd.sh"

  # Staged starship prompt (colors from config/starship.toml) — keeps the
  # prod-tripwire + ☸ keel showcase without photographing a real repo.
  local frame=$'\033[38;2;125;207;255m' fg=$'\033[38;2;192;202;245m'
  local blue=$'\033[1;38;2;122;162;247m' magenta=$'\033[1;38;2;187;154;247m'
  local green=$'\033[38;2;158;206;106m' red=$'\033[1;38;2;247;118;142m'
  local cyan=$'\033[1;38;2;125;207;255m' reset=$'\033[0m'
  print
  print -r -- "${frame}╭─${reset}${fg} ${reset}${blue} 🏠/code/chainproof-ledger ${reset}${magenta} main${reset} ${red}[${green} ${red}]${reset}  ${red} ⚠ prod!${reset}"
  print -rn -- "${cyan}╰─☸ ${reset}"
  print

  HOME=$OLD_HOME
  rm -rf "$STAGE"
}

capture > "$REPO_DIR/docs/motd.ansi"
echo "wrote $REPO_DIR/docs/motd.ansi" >&2
