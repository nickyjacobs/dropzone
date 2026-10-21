# menu: the interactive TUI of dz (dz without arguments), with an animated banner.
#
#   dz            open the menu (↑↓ move, Enter open, digit = jump, q/Esc back)
#
#   New box · Load box · Target › · Notes › · Mark done · Remove box · Unload box · Quit
#   Target ›  Change IP · Switch host · Add host · Deadline
#   Notes ›   Open note · Timeline entry · Add flag · To do · Finding · Creds
#   DZ_ART=3 dz   with a fixed art (1-10, see art.zsh)

typeset -ga _dz_logo_small=('D R O P Z O N E')
typeset -ga _dz_wave=(22 28 34 40 46 82 118 157 118 82 46 40 34 28)
typeset -ga _dz_spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
typeset -g  _dz_glyphs='01<>/\|=+*#%$@&?!:;{}[]~^'

# Spaces to centre something $1 characters wide, in $REPLY.
_dz_sp() {
  local -i p=$(( (COLUMNS - $1) / 2 ))
  (( p < 0 )) && p=0
  printf -v REPLY '%*s' $p ''
}

# Build one frame and send it to the terminal in one write (no flicker).
_dz_draw() {
  local -i f=$1 n=$#_dz_wave i c idx w wf=$1
  _dz_on DZ_ANIMATE || wf=0   # without animation the wave stands still
  local -a logo
  local buf=$'\e[H\n' line ch sp

  # Too narrow or too low for the art: compact banner.
  if (( COLUMNS >= ${#_dz_art[1]} + 2 && LINES >= $#_dz_art + 22 )); then
    logo=("${_dz_art[@]}")
  else
    logo=("${_dz_logo_small[@]}")
  fi
  w=${#logo[1]}
  # Form: a block 44 wide, centred.
  (( _dz_fpad = (COLUMNS - 44) / 2, _dz_fpad < 0 && (_dz_fpad = 0) ))
  _dz_sp $w; sp=$REPLY

  # Banner: scrambled first (random characters), then a wave from left to right.
  for line in "${logo[@]}"; do
    buf+=$sp
    for (( c = 1; c <= w; c++ )); do
      ch=$line[c]
      if [[ $ch == ' ' ]]; then
        buf+=' '
      elif (( f < _dz_reveal[c] )); then
        buf+=$'\e[38;5;34m'${_dz_glyphs[RANDOM%${#_dz_glyphs}+1]}
      elif [[ $ch == [╗║╔╝═╚─│┌┐└┘├┤] ]]; then
        buf+=$'\e[38;5;22m'$ch
      else
        (( idx = (c / 3 - wf) % n, idx < 0 && (idx += n) ))
        buf+=$'\e[1;38;5;'${_dz_wave[idx+1]}m$ch$'\e[22m'
      fi
    done
    buf+=$'\e[0m\e[K\n'
  done

  # Every line centred on its own: _dz_sp gets the visible length.
  _dz_sp $(( 10 + $#_dz_version ))
  buf+=$'\e[K\n'$REPLY$'\e[1;38;5;46mdropzone \e[0;38;5;248mv'$_dz_version$'\e[0m\e[K\n\e[K\n'

  # Status line: box, target (and the active host), time left, VPN. Pairs of label and
  # value; the length of the plain text centres it.
  local spin=${_dz_spin[f%${#_dz_spin}+1]} st='' plain='' k v col
  local -a seg=()
  if [[ -n $BOX ]]; then
    seg=(box $BOX target "$TARGET_IP${DZ_ACTIVE:+ ($DZ_ACTIVE)}")
    if [[ -n $DZ_DEADLINE ]]; then
      _dz_clock_short ${DZ_DEADLINE#* }
      seg+=(left "${REPLY:-time's up}")
    fi
  fi
  seg+=("$DZ_IFACE" "${_dz_tun:-down}")
  for k v in $seg; do
    col=118
    [[ $k == "$DZ_IFACE" && -z $_dz_tun ]] && col=196
    [[ $k == left ]] && { (( ${DZ_DEADLINE#* } - EPOCHSECONDS < 21600 )) && col=196 || col=214 }
    st+=$'\e[38;5;248m'$k$' \e[1;38;5;'$col'm'$v$'\e[0m   '
    plain+="$k $v   "
  done
  [[ -z $BOX ]] && { st=$'\e[38;5;248mno box loaded\e[0m   '$st; plain="no box loaded   $plain" }
  _dz_sp $#plain   # the spinner and its 3 spaces make up for the 3 at the end
  buf+=$REPLY$'\e[38;5;46m'$spin$'\e[0m  '$st$'\e[K\n\e[K\n'

  # Menu or box list
  if [[ $_dz_mode == form ]]; then
    local fm rule; printf -v fm '%*s' $_dz_fpad ''
    rule=${(l:44::─:)${:-}}
    _dz_sp $#_dz_title
    buf+=$REPLY$'\e[1;38;5;118m'$_dz_title$'\e[0m\e[K\n'$fm$'\e[38;5;28m'$rule$'\e[0m\e[K\n'
    _dz_formrow=$(( ${#logo} + 9 ))
  else
    if [[ $_dz_mode == (boxes|sub) ]]; then
      _dz_sp $#_dz_title
      buf+=$REPLY$'\e[1;38;5;118m'$_dz_title$'\e[0m\e[K\n\e[K\n'
    fi
    if (( ! $#_dz_items )); then
      [[ $_dz_purpose == host ]] && line="(no hosts in $BOX)" || line="(no boxes in $DZ_ROOT yet)"
      _dz_sp $#line
      buf+=$REPLY$'\e[38;5;248m'$line$'\e[0m\e[K\n'
    fi
    # Menu centred as a block, items left aligned inside it.
    local -i bw=0 first=1 last=$#_dz_items max
    for (( i = 1; i <= $#_dz_items; i++ )); do
      (( ${#_dz_items[i]} > bw )) && (( bw = ${#_dz_items[i]} ))
    done
    local -i nw=${#${#_dz_items}}; (( bw += nw + 1 ))   # numbers right aligned
    local num
    _dz_sp $(( bw + 4 )); local mp=$REPLY
    # A long box list scrolls: only the rows that fit, around the selection.
    if [[ $_dz_mode == boxes ]]; then
      (( max = LINES - ${#logo} - 14, max < 3 && (max = 3) ))
      if (( $#_dz_items > max )); then
        (( first = _dz_sel - max / 2, first < 1 && (first = 1) ))
        (( last = first + max - 1 ))
        (( last > $#_dz_items && (last = $#_dz_items, first = last - max + 1) ))
      fi
      (( first > 1 )) && buf+=$mp$'  \e[38;5;246m  ↑ '$(( first - 1 ))$' more\e[0m\e[K\n'
    fi
    for (( i = first; i <= last; i++ )); do
      num=${(l:nw:)i}
      if (( i == _dz_sel )); then
        buf+=$mp$'\e[1;38;5;46m▶ \e[7m '$num' '$_dz_items[i]$' \e[0m\e[K\n'
      elif (( _dz_off[i] )); then
        buf+=$mp$'  \e[38;5;238m '$num' '$_dz_items[i]$'\e[0m\e[K\n'
      else
        buf+=$mp$'  \e[38;5;250m '$num' '$_dz_items[i]$'\e[0m\e[K\n'
      fi
    done
    (( last < $#_dz_items )) && buf+=$mp$'  \e[38;5;246m  ↓ '$(( $#_dz_items - last ))$' more\e[0m\e[K\n'
    line='↑↓ move · Enter open · 1-9 jump · q back'
    _dz_sp $#line
    buf+=$'\e[K\n'$REPLY$'\e[38;5;246m'$line$'\e[0m\e[K\n'
  fi
  buf+=$'\e[J'
  print -rn -- $buf
}

_dz_set_main() {
  _dz_mode=main _dz_purpose=''
  _dz_items=('New box' 'Load box' 'Target ›' 'Notes ›' 'Mark done' 'Remove box' 'Unload box' 'Quit')
  _dz_off=(0 0 0 0 0 0 0 0)
  [[ -z $BOX ]] && _dz_off[3]=1 _dz_off[4]=1 _dz_off[5]=1 _dz_off[7]=1
  # Notes off and creds off: nothing in the Notes submenu works.
  [[ $DZ_NOTE_MODE == off ]] && ! _dz_on DZ_CREDS && _dz_off[4]=1
  (( _dz_sel > $#_dz_items )) && _dz_sel=1
}

# $1 = target or notes: the submenu of the loaded box.
_dz_set_sub() {
  _dz_mode=sub _dz_purpose=$1 _dz_sel=${2:-1}
  if [[ $1 == target ]]; then
    _dz_title="Target · $BOX"
    _dz_items=('Change IP' 'Switch host' 'Add host' 'Deadline')
    _dz_off=(0 0 0 0)
    _dz_box_read $DZ_ROOT/$BOX 2>/dev/null && (( $#_dz_bh )) || _dz_off[2]=1   # only the main host
  else
    _dz_title="Notes · $BOX"
    _dz_items=('Open note' 'Timeline entry' 'Add flag' 'To do' 'Finding' 'Creds')
    _dz_off=(0 0 0 0 0 0)
    [[ $DZ_NOTE_MODE == off ]] && _dz_off[1,5]=(1 1 1 1 1)
    _dz_on DZ_CREDS || _dz_off[6]=1
  fi
}

# The hosts of the loaded box to switch to (dz -t <host>): the main host first.
_dz_set_hosts() {
  local l mark
  local -a w
  _dz_mode=boxes _dz_purpose=host _dz_sel=1 _dz_title="Switch host · $BOX"
  _dz_boxnames=() _dz_items=() _dz_off=()
  _dz_box_read $DZ_ROOT/$BOX 2>/dev/null || return 0
  [[ -z $_dz_ba ]] && mark=active || mark=''
  _dz_boxnames+=$BOX; _dz_items+="${(r:20:)BOX} ${(r:16:)reply[2]}$mark"
  for l in $_dz_bh; do
    w=(${=l})
    [[ $w[1] == $_dz_ba ]] && mark=active || mark=''
    _dz_boxnames+=$w[1]; _dz_items+="${(r:20:)w[1]} ${(r:16:)w[2]}$mark"
    [[ -n $mark ]] && _dz_sel=$#_dz_items      # start on the active host
  done
}

# $1 = load or delete. Loading also lists the archive (loading one restores it).
_dz_set_boxes() {
  local d tag
  _dz_purpose=$1
  [[ $1 == delete ]] && _dz_title='Remove box' || _dz_title='Load box'
  _dz_mode=boxes _dz_sel=1 _dz_boxnames=() _dz_items=() _dz_off=()
  local -a dirs=($DZ_ROOT/*/.dropzone(Nn:h))
  [[ $1 == load ]] && dirs+=($DZ_ROOT/_archive/*/.dropzone(Nn:h))
  for d in $dirs; do
    _dz_box_read $d || continue
    _dz_boxnames+=${d:t}
    [[ ${d:h:t} == _archive ]] && tag=archived || tag=''
    _dz_items+="${(r:20:)${d:t}} ${(r:16:)reply[2]}$tag"
  done
}

# Form field under the title; empty input or Ctrl-C = cancel.
_dz_ask() {
  local __var=$1 prompt=$2
  # No history suggestions from zsh-autosuggestions in the form. Local, so only
  # while this field is open; your normal prompt keeps them.
  local _ZSH_AUTOSUGGEST_DISABLED=1
  local sp; printf -v sp '%*s' $_dz_fpad ''
  print -rn -- $'\e['$_dz_formrow$';1H\e[J\e[?25h'
  vared -p "$sp%F{252}${(r:14:)prompt}%F{46}›%f " $__var
  local rc=$?
  print -n $'\e[?25l'
  (( _dz_formrow++ ))
  return $rc
}

# Like _dz_ask, but nothing shows while you type (a password or hash).
_dz_ask_secret() {
  local __var=$1 prompt=$2 __val
  local sp; printf -v sp '%*s' $_dz_fpad ''
  print -rn -- $'\e['$_dz_formrow$';1H\e[J\e[?25h'$sp$'\e[38;5;252m'${(r:14:)prompt}$'\e[38;5;46m›\e[0m '
  stty icanon        # a whole line; -s keeps it hidden (read turns echo back on)
  IFS= read -rs __val
  local rc=$?
  stty -icanon
  print -n $'\e[?25l'
  (( _dz_formrow++ ))
  : ${(P)__var::=$__val}
  return $rc
}

# Yes/No choice under the title. ←→ (or Tab) switch, Enter confirms,
# y and n pick straight away, Esc cancels. $3 = default (y or n). Sets y or n.
_dz_choose() {
  local __var=$1 prompt=$2 key rest sp line
  local -i sel=1 opt
  [[ $3 == n ]] && sel=2
  local -a opts=(Yes No)
  printf -v sp '%*s' $_dz_fpad ''
  local label=$sp$'\e[38;5;252m'${(r:14:)prompt}$'\e[38;5;46m›\e[0m '
  while true; do
    line=$'\e['$_dz_formrow$';1H\e[J'$label
    for (( opt = 1; opt <= 2; opt++ )); do
      if (( opt == sel )); then
        line+=$'\e[1;38;5;16;48;5;46m '$opts[opt]$' \e[0m '
      else
        line+=$'\e[38;5;250;48;5;237m '$opts[opt]$' \e[0m '
      fi
    done
    _dz_sp 44
    line+=$'\n\n'$REPLY$'\e[38;5;246m←→ choose · Enter confirm · Esc cancel\e[0m'
    print -rn -- $line
    read -s -k 1 key || return 1
    if [[ $key == $'\e' ]]; then
      rest=''; read -s -t 0.01 -k 2 rest; key+=$rest
    fi
    case $key in
      $'\e[D'|$'\eOD') sel=1 ;;
      $'\e[C'|$'\eOC') sel=2 ;;
      $'\t'|$'\e[A'|$'\e[B'|$'\eOA'|$'\eOB') (( sel = 3 - sel )) ;;
      [yY]) sel=1; break ;;
      [nN]) sel=2; break ;;
      $'\n'|$'\r'|' ') break ;;
      $'\e') return 1 ;;
    esac
  done
  # Leave the chosen value, remove the hint.
  print -rn -- $'\e['$_dz_formrow$';1H\e[J'$label$'\e[1;38;5;118m'$opts[sel]$'\e[0m'
  (( _dz_formrow++ ))
  (( sel == 1 )) && : ${(P)__var::=y} || : ${(P)__var::=n}
  return 0
}

# Enter in a submenu. Works on the locals of _dz_menu (dynamic scope). Succeeds when
# an action is chosen (the menu closes and runs it), fails to stay in the menu.
_dz_menu_sub() {
  local cur
  case $_dz_purpose:$_dz_sel in
    target:1)
      _dz_mode=form _dz_title="New IP for $BOX"
      _dz_draw $f
      _dz_box_read $DZ_ROOT/$BOX && ip=$reply[2]       # the main host, not the active one
      cur=$ip
      _dz_ask ip 'ip' && [[ -n $ip && $ip != $cur ]] && { action=ip; return 0 } ;;
    target:2) _dz_set_hosts; return 1 ;;
    target:3)
      _dz_mode=form _dz_title="Add a host to $BOX (like dc01)"
      _dz_draw $f
      name='' ip='' host=''
      _dz_ask name 'host' && [[ -n $name ]] &&
        _dz_ask ip 'ip' && [[ -n $ip ]] &&
        _dz_ask host 'hostnames' && { action=addhost; return 0 } ;;
    target:4)
      _dz_clock_read $BOX && { _dz_clock_text $reply[1] $reply[2]; cur=$REPLY } || cur='none yet'
      _dz_mode=form _dz_title="Deadline for $BOX: $cur"
      _dz_draw $f
      text=''
      _dz_ask text '10d/date/none' && [[ -n $text ]] && { action=deadline; return 0 } ;;
    notes:1) action=open; return 0 ;;
    notes:2)
      _dz_mode=form _dz_title="Timeline of $BOX"
      _dz_draw $f
      text=''
      _dz_ask text 'entry' && [[ -n $text ]] && { action=journal; return 0 } ;;
    notes:3)
      _dz_mode=form _dz_title="Flag for ${DZ_ACTIVE:-$BOX}"
      _dz_draw $f
      text=''
      _dz_ask text 'flag' && [[ -n $text ]] && { action=flag; return 0 } ;;
    notes:4)
      _dz_mode=form _dz_title="To do for ${DZ_ACTIVE:-$BOX} (dz --todo lists them)"
      _dz_draw $f
      text=''
      _dz_ask text 'to do' && [[ -n $text ]] && { action=todo; return 0 } ;;
    notes:5)
      _dz_mode=form _dz_title="New finding on ${DZ_ACTIVE:-$BOX}: -s and -e go under it"
      _dz_draw $f
      text=''
      _dz_ask text 'title' && [[ -n $text ]] && { action=finding; return 0 } ;;
    notes:6)
      _dz_mode=form _dz_title="Creds for $BOX (the secret doesn't show)"
      _dz_draw $f
      name='' secret=''
      _dz_ask name 'user' && [[ -n $name ]] &&
        _dz_ask_secret secret 'secret' && [[ -n $secret ]] && { action=creds; return 0 } ;;
  esac
  _dz_set_sub $_dz_purpose $_dz_sel
  return 1
}

# The interactive menu (dz without arguments).
_dz_menu() {
  emulate -L zsh
  [[ -t 0 && -t 1 ]] || { _dz_err E107 "not an interactive terminal"; return 1 }

  local -i f=0 tick=0
  local key rest action='' name ip host text secret
  local -a _dz_items _dz_boxnames _dz_reveal _dz_off
  local stty_save=$(stty -g)
  local _dz_mode _dz_title _dz_tun _dz_purpose conf rmnote
  local -i _dz_sel=1 _dz_formrow _dz_fpad c pick last=0
  local -a _dz_art

  # Pick an art: random, but never the same as last time.
  local artlast=${XDG_CACHE_HOME:-$HOME/.cache}/dz-art-last
  [[ -r $artlast ]] && last=$(<$artlast)
  if [[ $DZ_ART == <1-> ]] && (( DZ_ART <= _dz_art_count )); then
    pick=$DZ_ART
  elif (( last >= 1 && last <= _dz_art_count )); then
    (( pick = RANDOM % (_dz_art_count - 1) + 1, pick >= last && pick++ ))
  else
    (( pick = RANDOM % _dz_art_count + 1 ))
  fi
  mkdir -p ${artlast:h} && print $pick > $artlast
  _dz_art=("${(@P)${:-_dz_art_$pick}}")

  for (( c = 1; c <= ${#_dz_art[1]}; c++ )); do
    _dz_on DZ_ANIMATE && _dz_reveal[c]=$(( c / 5 + RANDOM % 12 )) || _dz_reveal[c]=0
  done
  _dz_tun=$(_dz_attacker_ip)
  _dz_set_main

  stty -echo -icanon
  print -n $'\e[?1049h\e[?25l\e[2J'
  {
    while true; do
      (( tick++ % 15 == 0 )) && _dz_tun=$(_dz_attacker_ip)
      _dz_draw $f
      (( f++ ))
      read -s -t 0.06 -k 1 key || continue
      if [[ $key == $'\e' ]]; then
        rest=''; read -s -t 0.01 -k 2 rest; key+=$rest
      fi
      case $key in
        $'\e[A'|$'\eOA') (( _dz_sel = _dz_sel > 1 ? _dz_sel - 1 : $#_dz_items )) ;;
        $'\e[B'|$'\eOB') (( _dz_sel = _dz_sel < $#_dz_items ? _dz_sel + 1 : 1 )) ;;
        q|$'\e')
          case $_dz_mode:$_dz_purpose in
            boxes:host)   _dz_set_sub target 2; continue ;;
            boxes:delete) _dz_sel=6; _dz_set_main; continue ;;
            boxes:*)      _dz_sel=2; _dz_set_main; continue ;;
            sub:target)   _dz_sel=3; _dz_set_main; continue ;;
            sub:notes)    _dz_sel=4; _dz_set_main; continue ;;
          esac
          break ;;
        [1-9]|$'\n'|$'\r'|' ')
          if [[ $key == [1-9] ]]; then
            (( key <= $#_dz_items )) || continue
            _dz_sel=$key
          fi
          (( $#_dz_items )) || continue
          (( _dz_off[_dz_sel] )) && continue
          if [[ $_dz_mode == boxes ]]; then
            name=$_dz_boxnames[_dz_sel]
            [[ $_dz_purpose == load ]] && { action=load; break }
            [[ $_dz_purpose == host ]] && { action=host; break }
            _dz_mode=form _dz_title="Remove box $name (goes to the trash)"
            _dz_draw $f
            conf='' rmnote=''
            _dz_choose conf 'sure?' n && [[ $conf == y ]] &&
              { [[ $DZ_NOTE_MODE != vault || ! -f $(_dz_note $name) ]] || _dz_choose rmnote 'note too?' n } &&
              { action=rm; break }
            _dz_sel=6; _dz_set_main; continue
          fi
          if [[ $_dz_mode == sub ]]; then
            _dz_menu_sub && break
            continue
          fi
          case $_dz_sel in
            1)
              _dz_mode=form _dz_title='New box'
              _dz_draw $f
              name='' ip='' host=''
              _dz_ask name 'name' && [[ -n $name ]] &&
                _dz_ask ip 'ip' && [[ -n $ip ]] &&
                _dz_ask host 'hostnames' &&
                { action=new; break }
              _dz_set_main ;;
            2) _dz_set_boxes load ;;
            3) _dz_set_sub target ;;
            4) _dz_set_sub notes ;;
            5)
              _dz_mode=form _dz_title="Mark $BOX done (status: done)"
              _dz_draw $f
              conf=''
              _dz_choose conf 'archive?' n && { [[ $conf == y ]] && action=archive || action=done; break }
              _dz_sel=5; _dz_set_main ;;
            6) _dz_set_boxes delete ;;
            7) _dz_off; _dz_sel=1; _dz_set_main ;;
            8) break ;;
          esac ;;
      esac
    done
  } always {
    print -n $'\e[0m\e[?25h\e[?1049l'
    stty $stty_save
  }

  case $action in
    new)  _dz_new $name $ip "$host" ;;
    ip)   _dz_new $BOX $ip ;;
    host) _dz_target "$name" ;;
    addhost) _dz_target "$name" "$ip" "$host" ;;
    deadline) _dz_deadline "$text" ;;
    journal) _dz_journal "$text" ;;
    flag) _dz_flag '' "$text" ;;
    todo) _dz_todo "$text" new ;;
    finding) _dz_finding "$text" new ;;
    creds) _dz_creds "$name:$secret" ;;
    rm)   [[ $rmnote == y ]] && _dz_rm $name 1 yes || _dz_rm $name 1 no ;;
    open) _dz_open ;;
    done) _dz_done ;;
    archive) _dz_archive ;;
    load) _dz_workon $name && print "• BOX=$BOX  TARGET_IP=$TARGET_IP  ATTACKER_IP=${ATTACKER_IP:-<$DZ_IFACE down>}" ;;
  esac
}
