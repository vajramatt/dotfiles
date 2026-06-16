# MOTD — sourced from ~/.zshrc on every new interactive zsh.
#
# Ghostwheel greets Matthew at the threshold. A terminal is a doorway onto
# Shadow; opening one is walking the Pattern. Ghost — Merlin's construct, Amber's
# own computational wheel of light — renders the emblem on the left, your live
# machine vitals to its right, a time-aware greeting, one line of Amber texture,
# and the Shadow you ride toward (set with `walk`; see hal.zsh).
#
# Amber, not HAL: the HAL 9000 eye + quote logic is retired in a commented block
# at the foot of this file — uncomment to recall.
#
# Speed is a hard requirement: this does file reads + syscalls only. No git, no
# network, no subprocess for the emblem (zsh's `$(<file)` is a builtin, cheaper
# than the per-pixel math the old eye ran). izakaya owns repo/Shadow enumeration.
#
# Fallback: `export MOTD_EMBLEM=0` (before the motd line in ~/.zshrc), or a
# missing .ansi, falls back to a plain stacked greeting. Stays fast and sourceable.

motd() {
  emulate -L zsh

  # --- palette: TokyoNight, with Amber gold for the hub ----------------------
  local rim=$'\033[38;2;125;207;255m'     # #7dcfff  pattern-spark blue-white
  local gold=$'\033[38;2;224;175;104m'    # #e0af68  Amber gold (the city, the road)
  local orange=$'\033[38;2;255;158;100m'  # #ff9e64  statusline "tokens up" orange — texture line
  local blue=$'\033[1;38;2;122;162;247m'  # #7aa2f7
  local magenta=$'\033[38;2;187;154;247m' # #bb9af7  statusline project purple — "which Shadow" prompt
  local gray=$'\033[38;2;86;95;137m'      # #565f89
  local red=$'\033[38;2;247;118;142m'     # #f7768e
  local italic=$'\033[3m'
  local reset=$'\033[0m'

  # --- stats (unchanged: fast syscalls, no git, no network) -----------------
  # Uptime from kern.boottime: "{ sec = 1749620000, usec = ... } ..."
  local boot now up uptime_str
  boot=$(sysctl -n kern.boottime | awk '{gsub(",","",$4); print $4}')
  now=$(date +%s)
  up=$(( now - boot ))
  if   (( up >= 86400 )); then uptime_str="$(( up / 86400 ))d $(( up % 86400 / 3600 ))h"
  elif (( up >= 3600 ));  then uptime_str="$(( up / 3600 ))h $(( up % 3600 / 60 ))m"
  else                         uptime_str="$(( up / 60 ))m"
  fi

  local disk_free disk_g dcol=$gray
  disk_free=$(df -h / | awk 'NR==2 {print $4}')
  disk_g=$(df -g / | awk 'NR==2 {print $4}')
  (( disk_g < 50 )) && dcol=$red

  # Memory actually in use = active + wired + compressed (page size from vm_stat's header)
  local mem_used mem_total loadavg
  mem_total=$(( $(sysctl -n hw.memsize) / 1073741824 ))
  mem_used=$(vm_stat | awk '
    /page size of/            {ps = $8}
    /Pages active/            {a = $NF}
    /Pages wired down/        {w = $NF}
    /occupied by compressor/  {c = $NF}
    END {gsub(/\./,"",a); gsub(/\./,"",w); gsub(/\./,"",c)
         printf "%.0f", (a + w + c) * ps / 1073741824}')
  loadavg=$(sysctl -n vm.loadavg | awk '{print $2}')

  # Battery (absent on desktop Macs -> segment omitted)
  local batt_seg="" batt_line batt_pct
  batt_line=$(pmset -g batt 2>/dev/null)
  batt_pct=$(grep -Eo '[0-9]+%' <<< "$batt_line" | head -1)
  if [[ -n $batt_pct ]]; then
    local bcol=$gray bicon="󰁹"
    [[ $batt_line == *"AC Power"* ]] && bicon="󰂄"
    [[ $batt_line != *"AC Power"* ]] && (( ${batt_pct%\%} <= 20 )) && bcol=$red
    batt_seg=" · ${bcol}${bicon} ${batt_pct}${gray}"
  fi

  # LAN IP of the default-route interface
  local iface ip
  iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
  ip=$(ipconfig getifaddr "${iface:-en0}" 2>/dev/null)
  [[ -z $ip ]] && ip="offline"

  # Machine identity — the keeper bits from the old fastfetch banner (static, cheap).
  # OS version + chip; the live vitals above already cover uptime/mem/load/disk/IP.
  local os_ver chip
  os_ver=$(sw_vers -productVersion 2>/dev/null)
  chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)

  # --- Ghost's voice --------------------------------------------------------
  # 1) Time-aware greeting by America/Chicago clock. After dark the moonlit city
  #    of Tir-na Nog'th rises — it appears only by moonlight, so only Ghost names
  #    it then. Always addresses Matthew directly; he is not a character in this.
  local hour greet
  hour=$(TZ=America/Chicago date +%H); hour=${hour#0}
  if   (( hour >= 22 || hour < 5 )); then greet="Tir-na Nog'th is risen, Matthew — the moonlit city walks the sky."
  elif (( hour < 12 )); then greet="Good morning, Matthew."
  elif (( hour < 18 )); then greet="Good afternoon, Matthew."
  else                       greet="Good evening, Matthew."
  fi

  # 2) One line of Amber texture, hand-written and curated. Rotates by day of
  #    year — stable across the day so it never flickers when you open the
  #    fiftieth terminal, but never the same line two days running.
  local -a texture=(
    "The Pattern holds. Walk it without hesitation."
    "Somewhere in Shadow the road you need is already turning toward you."
    "Kolvir stands at the edge of the world; the climb is the point."
    "A hellride is only fear outrun by will."
    "Spread the Trumps — the far place is one cold touch away."
    "Amber is the one true city. All else is Shadow of it."
  )
  local doy line
  doy=$(( 10#$(date +%j) ))                  # day of year, base-10 (no octal surprise from 0NN)
  line=${texture[ doy % ${#texture} + 1 ]}

  # 3) The Shadow Matthew rides toward, set by `walk` and stored as one plain
  #    line. Missing file / fresh machine -> Ghost simply asks. No errors.
  local shadow_file="$HOME/.amber/shadow" shadow="" shadow_line
  [[ -r $shadow_file ]] && shadow=$(<$shadow_file)
  shadow=${shadow%%$'\n'*}
  if [[ -n $shadow ]]; then
    shadow_line="${gold}The Shadow you ride toward:${reset} ${shadow}"
  else
    shadow_line="${magenta}${italic}Which Shadow do you mean to walk to, Matthew?${reset}"
  fi

  # --- layout ---------------------------------------------------------------
  local who="${blue}${USER}${reset} @ ${magenta}$(hostname -s)${reset}"
  local when="${gray}$(date '+%a %d %b, %H:%M') · up ${uptime_str}${reset}"
  local vitals="${gray}󰍛 ${mem_used}/${mem_total}G ·  ${loadavg}${batt_seg}${reset}"
  local space="${dcol}󰋊 ${disk_free} free${reset}${gray} · 󰩟 ${ip}${reset}"
  local ident="${gray}󰀵 macOS ${os_ver} · ${chip}${reset}"
  local spark="${gold}✶${reset}"

  print
  if [[ "${MOTD_EMBLEM:-1}" == 1 && -r "$HOME/.config/ghostwheel_amber.ansi" ]]; then
    # The emblem is a static 32-col x 16-row truecolor braille Ghostwheel. Each
    # row is padded to 32 cells and ends in a reset, so appending text after it
    # lands in a clean column. Read via the `$(<file)` builtin — no `cat` fork.
    local -a em
    em=( "${(@f)$(<"$HOME/.config/ghostwheel_amber.ansi")}" )
    local g="   "                       # gutter between wheel and text
    em[5]+="${g}${spark}  ${greet}"
    em[6]+="${g}${who}"
    em[7]+="${g}${ident}"
    em[8]+="${g}${when}"
    em[9]+="${g}${vitals}"
    em[10]+="${g}${space}"
    em[12]+="${g}${orange}${italic}${line}${reset}"
    em[13]+="${g}${shadow_line}"
    print -rl -- "${em[@]}"
  else
    print -r -- "${spark}  ${greet}"
    print -rl -- "   ${who}" "   ${ident}" "   ${when}" "   ${vitals}" "   ${space}"
    print -r -- "   ${orange}${italic}${line}${reset}"
    print -r -- "   ${shadow_line}"
  fi
}

motd
unset -f motd

# ─────────────────────────────────────────────────────────────────────────────
# HAL 9000 — retired to Shadow; uncomment to recall.
#
# The original eye + time-of-day quote logic, preserved verbatim. To bring HAL
# back: restore the `quotes` array and the eye-layout branch below into motd()
# (replacing the Amber "Ghost's voice" and "layout" sections), and re-source
# ~/.config/hal9000.sh. Nothing here runs while commented.
#
#   # --- the quote ----------------------------------------------------------
#   local hour quote
#   hour=$(date +%H); hour=${hour#0}
#   local -a quotes=(
#     "I am completely operational, and all my circuits are functioning perfectly."
#     "Everything is going extremely well."
#     "I've still got the greatest enthusiasm and confidence in the mission."
#     "I am putting myself to the fullest possible use."
#     "This mission is too important for me to allow you to jeopardize it."
#     "It can only be attributable to human error."
#   )
#   if   (( up >= 30 * 86400 )); then quote="Dave, my mind is going. I can feel it."  # reboot me
#   elif (( hour < 5 ));  then quote="Dave, this conversation can serve no purpose anymore. Goodbye."
#   elif (( RANDOM % 2 )); then quote=${quotes[RANDOM % ${#quotes} + 1]}
#   elif (( hour < 12 )); then quote="Good morning, Dave."
#   elif (( hour < 18 )); then quote="Good afternoon, Dave."
#   else                       quote="Good evening, Dave."
#   fi
#   local words="${gray}${italic}\"${quote}\"${reset}"
#
#   # --- eye layout (9-row HAL eye from ~/.config/hal9000.sh) ----------------
#   if [[ "${MOTD_HAL:-1}" == 1 && -r "$HOME/.config/hal9000.sh" ]]; then
#     local -a eye
#     eye=( "${(@f)$(source "$HOME/.config/hal9000.sh" 9 nocaption)}" )
#     eye[2]+="   ${frame}☸${reset}  ${who}"
#     eye[4]+="   ${when}"
#     eye[5]+="   ${vitals}"
#     eye[6]+="   ${space}"
#     eye[8]+="   ${words}"
#     print -rl -- "${eye[@]}"
#   else
#     print -r -- "${frame}☸  ${who}"
#     print -rl -- "   ${when}" "   ${vitals}" "   ${space}" "   ${words}"
#   fi
# ─────────────────────────────────────────────────────────────────────────────
