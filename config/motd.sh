# MOTD — sourced from ~/.zshrc on every new interactive zsh.
# TokyoNight palette + a compact HAL 9000 eye (rendered by ~/.config/hal9000.sh)
# with live machine stats laid out to its right and a HAL quote beneath.
#
# Magic:
#   - battery (when discharging ≤20%) and disk (<50G free) turn red
#   - the quote is time-of-day aware; past 30d uptime HAL's mind starts going
#
# Skeptical of the eye? `export MOTD_HAL=0` (before the motd line in ~/.zshrc)
# falls back to a plain stacked greeting. Must stay fast and sourceable.

motd() {
  emulate -L zsh
  local frame=$'\033[38;2;125;207;255m'   # #7dcfff
  local blue=$'\033[1;38;2;122;162;247m'  # #7aa2f7
  local magenta=$'\033[38;2;187;154;247m' # #bb9af7
  local gray=$'\033[38;2;86;95;137m'      # #565f89
  local red=$'\033[38;2;247;118;142m'     # #f7768e
  local italic=$'\033[3m'
  local reset=$'\033[0m'

  # --- stats ----------------------------------------------------------------
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

  # --- the quote ------------------------------------------------------------
  local hour quote
  hour=$(date +%H); hour=${hour#0}
  local -a quotes=(
    "I am completely operational, and all my circuits are functioning perfectly."
    "Everything is going extremely well."
    "I've still got the greatest enthusiasm and confidence in the mission."
    "I am putting myself to the fullest possible use."
    "This mission is too important for me to allow you to jeopardize it."
    "It can only be attributable to human error."
  )
  if   (( up >= 30 * 86400 )); then quote="Dave, my mind is going. I can feel it."  # reboot me
  elif (( hour < 5 ));  then quote="Dave, this conversation can serve no purpose anymore. Goodbye."
  elif (( RANDOM % 2 )); then quote=${quotes[RANDOM % ${#quotes} + 1]}
  elif (( hour < 12 )); then quote="Good morning, Dave."
  elif (( hour < 18 )); then quote="Good afternoon, Dave."
  else                       quote="Good evening, Dave."
  fi

  # --- layout ---------------------------------------------------------------
  local who="${blue}${USER}${reset} @ ${magenta}$(hostname -s)${reset}"
  local when="${gray}$(date '+%a %d %b, %H:%M') · up ${uptime_str}${reset}"
  local vitals="${gray}󰍛 ${mem_used}/${mem_total}G ·  ${loadavg}${batt_seg}${reset}"
  local space="${dcol}󰋊 ${disk_free} free${reset}${gray} · 󰩟 ${ip}${reset}"
  local words="${gray}${italic}\"${quote}\"${reset}"

  print
  if [[ "${MOTD_HAL:-1}" == 1 && -r "$HOME/.config/hal9000.sh" ]]; then
    # 9-row eye; lines are fixed-width so += aligns the column of text.
    local -a eye
    eye=( "${(@f)$(source "$HOME/.config/hal9000.sh" 9 nocaption)}" )
    eye[2]+="   ${frame}☸${reset}  ${who}"
    eye[4]+="   ${when}"
    eye[5]+="   ${vitals}"
    eye[6]+="   ${space}"
    eye[8]+="   ${words}"
    print -rl -- "${eye[@]}"
  else
    print -r -- "${frame}☸  ${who}"
    print -rl -- "   ${when}" "   ${vitals}" "   ${space}" "   ${words}"
  fi
}

motd
unset -f motd
