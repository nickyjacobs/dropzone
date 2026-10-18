# clock: a deadline per box, for an exam with a time limit.
#
#   dz --deadline 10d                 from now: 10d, 48h or 9d12h
#   dz --deadline 2026-12-10T14:00    until a date and time (a date alone = 23:59)
#   dz --deadline                     show it
#   dz --deadline none                remove it
#
# Stored in ~/boxes/<box>/.deadline (start= and end=, seconds since 1970), read, never run.
# dz -i and the prompt show what's left: [cpts 10.129.5.10 5d22h]-.

# reply=(start end) of box $1, fails when it has no deadline.
_dz_clock_read() {
  local f=$DZ_ROOT/$1/.deadline l s='' e=''
  [[ -f $f ]] || return 1
  while IFS= read -r l || [[ -n $l ]]; do
    case $l in
      start=<->) s=${l#*=} ;;
      end=<->)   e=${l#*=} ;;
    esac
  done < $f
  [[ -n $s && -n $e ]] && (( e > s )) && reply=($s $e)
}

# Time left until $1 (seconds since 1970) in $REPLY: 5d22h, 3h10m, 12m, or empty when over.
_dz_clock_short() {
  local -i left=$(( $1 - EPOCHSECONDS ))
  if (( left <= 0 )); then REPLY=''
  elif (( left >= 86400 )); then REPLY=$(( left / 86400 ))d$(( left % 86400 / 3600 ))h
  elif (( left >= 3600 )); then REPLY=$(( left / 3600 ))h$(( left % 3600 / 60 ))m
  else REPLY=$(( left / 60 ))m
  fi
}

# "day 4/10 · 5d22h left (until 2026-12-10 14:00)" for start $1 and end $2, in $REPLY.
_dz_clock_text() {
  local -i s=$1 e=$2 days=$(( ($2 - $1 + 86399) / 86400 )) day=$(( (EPOCHSECONDS - $1) / 86400 + 1 ))
  local until; strftime -s until '%F %H:%M' $e
  _dz_clock_short $e
  if [[ -z $REPLY ]]; then
    REPLY="time's up (ended $until)"
  else
    (( day > days )) && day=$days
    REPLY="day $day/$days · $REPLY left (until $until)"
  fi
}

# Seconds since 1970 for a deadline: a duration from now, or a date and time. In $REPLY.
_dz_clock_parse() {
  emulate -L zsh
  local w=$1 t
  if [[ $w =~ '^([0-9]+d)?([0-9]+h)?$' && -n $w ]]; then
    local -i d=${${match[1]%d}:-0} h=${${match[2]%h}:-0}
    REPLY=$(( EPOCHSECONDS + d * 86400 + h * 3600 ))
  elif [[ $w =~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}([T ][0-9]{2}:[0-9]{2})?$' ]]; then
    [[ -n $match[1] ]] && w=${w/T/ } || w="$w 23:59"
    strftime -r -s t '%Y-%m-%d %H:%M' $w 2>/dev/null || return 1
    REPLY=$t
  else
    return 1
  fi
}

# dz --deadline [when]
_dz_deadline() {
  emulate -L zsh
  [[ -n $BOX ]] || { _dz_err E201 "no box loaded"; return 1 }
  local f=$DZ_ROOT/$BOX/.deadline note
  note=$(_dz_note $BOX 2>/dev/null) || note=''
  case $1 in
    ''|show)
      _dz_clock_read $BOX || { print "no deadline for $BOX (dz --deadline 10d)"; return 0 }
      _dz_clock_text $reply[1] $reply[2]; print "• $BOX: $REPLY" ;;
    none)
      rm -f $f; unset DZ_DEADLINE; print "• deadline of $BOX removed" ;;
    *)
      _dz_clock_parse $1 ||
        { _dz_err E801 "'$1' is not a deadline: 10d, 48h, 9d12h or 2026-12-10T14:00"; return 1 }
      local -i e=$REPLY s=$EPOCHSECONDS
      (( e > s )) || { _dz_err E802 "that's in the past"; return 1 }
      # A new end keeps the start, so 'day 4/10' stays right when you correct the end.
      _dz_clock_read $BOX && s=$reply[1]
      print -r -- "# dropzone deadline. Read by dz, never run."$'\n'"start=$s"$'\n'"end=$e" > $f
      typeset -g DZ_DEADLINE="$s $e"
      _dz_clock_text $s $e
      print "• $BOX: $REPLY"
      [[ -f $note ]] && { local u; strftime -s u '%F %H:%M' $e; _dz_timeline_add $note "deadline: $u" } ;;
  esac
}
