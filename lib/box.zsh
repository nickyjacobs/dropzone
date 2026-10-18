# box: the box logic behind dz (folder, vault note, target variables, /etc/hosts, cleanup).
# Everything here is internal (_dz_*); you use it through dz, see dz --help.
#
# Every box folder has a .dropzone file with its name, IP and hostnames. dropzone reads
# it line by line and never runs it, so a target's .env that ends up in the folder
# (git-dumper, unpacked loot) can't execute anything.

# Starts with a letter or digit, so '.', '..' and '_archive' can never be a box name.
_dz_name_re='^[A-Za-z0-9][A-Za-z0-9._-]*$'

_dz_valid_name() { [[ $1 =~ $_dz_name_re ]] }
_dz_valid_host() { [[ $1 =~ '^[A-Za-z0-9][A-Za-z0-9.-]*$' ]] }
# Extra hosts in a box (dz -t): lowercase, digits and '-', like dc01 or ms-02.
_dz_valid_label() { [[ $1 =~ '^[a-z0-9][a-z0-9-]*$' ]] }
# Variable for a host: dc01 -> DC01_IP, ms-02 -> MS_02_IP.
_dz_label_var() { REPLY=${(U)1//-/_}_IP }
_dz_valid_ip() {
  [[ $1 =~ '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' ]] || return 1
  local o; for o in ${(s:.:)1}; do (( 10#$o <= 255 )) || return 1; done
}

_dz_attacker_ip() {
  ip -4 -br addr show $DZ_IFACE 2>/dev/null | awk '{print $3; exit}' | cut -d/ -f1
}

# $ATTACKER_IP again from the interface. Also runs before every prompt, at most every
# 10 seconds, so a VPN reconnect with a new IP is picked up.
_dz_attacker_refresh() { typeset -gx ATTACKER_IP=$(_dz_attacker_ip); typeset -gi _dz_ip_ts=$EPOCHSECONDS }
_dz_precmd() { [[ -n $BOX ]] && (( EPOCHSECONDS - ${_dz_ip_ts:-0} >= 10 )) && _dz_attacker_refresh; return 0 }
add-zsh-hook precmd _dz_precmd

# _dz_box_read <folder>: reply=(name ip hosts) for the main host. Extra hosts (dz -t) go
# to _dz_bh ("label ip hostname..." per host) and the active one to _dz_ba (empty = main).
# Fails on a missing or invalid file.
_dz_box_read() {
  emulate -L zsh
  local f=$1/.dropzone line name='' ip='' hosts='' active='' h
  local -a extra=() w
  typeset -ga _dz_bh=(); typeset -g _dz_ba=''
  [[ -f $f ]] || return 1
  while IFS= read -r line || [[ -n $line ]]; do
    case $line in
      name=*)   name=${line#*=} ;;
      ip=*)     ip=${line#*=} ;;
      hosts=*)  hosts=${line#*=} ;;
      active=*) active=${line#*=} ;;
      host=*)   extra+=("${line#*=}") ;;
    esac
  done < $f
  [[ $name == ${1:t} ]] && _dz_valid_name $name && _dz_valid_ip $ip || return 1
  for h in ${=hosts}; do _dz_valid_host $h || return 1; done
  for line in $extra; do
    w=(${=line})
    _dz_valid_label $w[1] && _dz_valid_ip $w[2] || return 1
    for h in $w[3,-1]; do _dz_valid_host $h || return 1; done
  done
  _dz_bh=("${extra[@]}")
  [[ -n ${(M)extra:#$active *} ]] && _dz_ba=$active
  reply=($name $ip "$hosts")
}

# _dz_box_write <folder> <name> <ip> <hosts> [active [host-line...]]
_dz_box_write() {
  local d=$1 name=$2 ip=$3 hosts=$4 active=$5 l
  shift 5 2>/dev/null || shift $#
  {
    print -r -- "# dropzone box. Read by dz, never run. Change it with dz, not by hand."
    print -r -- "name=$name"
    print -r -- "ip=$ip"
    print -r -- "hosts=$hosts"
    [[ -n $active ]] && print -r -- "active=$active"
    for l in "$@"; do print -r -- "host=$l"; done
  } > $d/.dropzone
}

# Boxes from older versions have a .env (BOX=, TARGET_IP=, DOMAIN=). Convert it, but only
# when it really is ours: every line one of those three keys, with valid values.
_dz_migrate() {
  emulate -L zsh
  local env d line k v name ip host ok
  for env in $DZ_ROOT/*/.env(N) $DZ_ROOT/_archive/*/.env(N); do
    d=${env:h}
    [[ -e $d/.dropzone ]] && continue
    name='' ip='' host='' ok=1
    while IFS= read -r line || [[ -n $line ]]; do
      [[ -z $line ]] && continue
      k=${line%%=*} v=${line#*=}
      [[ $v == \'*\' ]] && v=${${v#\'}%\'}
      case $k in
        BOX) name=$v ;; TARGET_IP) ip=$v ;; DOMAIN) host=$v ;;
        *) ok=0; break ;;
      esac
    done < $env
    (( ok )) && [[ $name == ${d:t} ]] && _dz_valid_name $name && _dz_valid_ip $ip || continue
    [[ -z $host ]] || _dz_valid_host $host || continue
    _dz_box_write $d $name $ip $host && rm -f $env
  done
  return 0
}

# Update the IP in the box note: $TARGET_IP placeholders and the old IP become the
# new IP. Exact match, so 10.10.10.1 leaves 10.10.10.15 alone. Prints the count.
_dz_note_ip() {
  local note=$1 old=$2 new=$3
  [[ -f $note ]] || { print 0; return }
  OLD=$old NEW=$new TODAY=$(date +%F) perl -0777 -pi -e '
    $n = s/\$TARGET_IP\b|\$\{TARGET_IP\}/$ENV{NEW}/g;
    $n += s/(?<![\d.])\Q$ENV{OLD}\E(?!\.?\d)/$ENV{NEW}/g
      if length $ENV{OLD} && $ENV{OLD} ne $ENV{NEW};
    s/^updated: .*$/updated: $ENV{TODAY}/m if $n;
    print STDERR $n + 0;
  ' $note 2>&1 >/dev/null | tail -1
}

# Change /etc/hosts. sudo only when the file isn't writable.
_dz_hosts_run() { if [[ -w $DZ_HOSTS ]]; then "$@"; else sudo "$@"; fi }

# The tag on /etc/hosts lines, as a regex without the end anchor ('.' in a name is literal):
#   _dz_hosts_re jacops        the main host        # dz:jacops
#   _dz_hosts_re jacops/dc01   an extra host        # dz:jacops/dc01
#   _dz_hosts_re jacops all    every line of the box
_dz_hosts_re() {
  REPLY="# dz:${1//./\\.}"
  [[ $2 == all ]] && REPLY+='(/[a-z0-9-]+)?'
  return 0
}
_dz_hosts_has() { grep -qE "$1\$" $DZ_HOSTS 2>/dev/null }

# Remove lines matching regex $1 from $DZ_HOSTS, after a backup ($DZ_HOSTS.dz.bak).
_dz_hosts_del() {
  _dz_hosts_has $1 || return 0
  _dz_hosts_run cp $DZ_HOSTS $DZ_HOSTS.dz.bak || return 1
  _dz_hosts_run perl -ni -e "print unless m{$1\\n?\\z}" $DZ_HOSTS
}

# _dz_hosts_set <tag> [ip] [hosts]: backup first ($DZ_HOSTS.dz.bak), then remove the line
# with this tag (box or box/host) and, with hosts, add the new one.
_dz_hosts_set() {
  emulate -L zsh
  local tag=$1 ip=$2 hosts=$3 re
  _dz_hosts_re $tag; re=$REPLY
  _dz_hosts_has $re || [[ -n $hosts ]] || return 0
  _dz_hosts_run cp $DZ_HOSTS $DZ_HOSTS.dz.bak || return 1
  if _dz_hosts_has $re; then
    _dz_hosts_run perl -ni -e "print unless m{$re\\n?\\z}" $DZ_HOSTS || return 1
  fi
  [[ -z $hosts ]] && return 0
  printf '%s\t%s\t# dz:%s\n' $ip "$hosts" $tag | _dz_hosts_run tee -a $DZ_HOSTS >/dev/null
}

# All /etc/hosts lines of a box: from the box file (main host and every extra host).
_dz_hosts_all() {
  local box=$1 l
  local -a w
  _dz_box_read $DZ_ROOT/$box || _dz_box_read $DZ_ROOT/_archive/$box || return 1
  local ip=$reply[2] hosts=$reply[3]
  [[ -n $hosts ]] && _dz_hosts_set $box $ip "$hosts"
  for l in $_dz_bh; do
    w=(${=l})
    (( $#w > 2 )) && _dz_hosts_set $box/$w[1] $w[2] "$w[3,-1]"
  done
  return 0
}

# Is the VPN up, and does the route to $1 go through it? Only a warning, never blocks.
_dz_vpn_check() {
  _dz_on DZ_VPNCHECK && (( $+commands[ip] )) || return 0
  if ! ip link show $DZ_IFACE >/dev/null 2>&1; then
    _dz_warn W201 "$DZ_IFACE doesn't exist, is your VPN connected? (iface in the config)"
    return 0
  fi
  local -a w=(${(z)"$(ip route get $1 2>/dev/null)"})
  local dev=${w[${w[(i)dev]}+1]} p
  [[ -z $dev || $dev == $DZ_IFACE ]] && return 0
  # A host behind a pivot (ligolo-ng, ...) is routed through the tunnel, that's fine.
  for p in $DZ_PIVOT; do [[ $dev == ${~p} ]] && return 0; done
  _dz_warn W202 "the route to $1 goes through $dev, not $DZ_IFACE${DZ_PIVOT:+ or a pivot ($DZ_PIVOT)}"
  return 0
}

# One ping, for info only.
_dz_ping() {
  if ping -c 1 -W 1 $1 >/dev/null 2>&1; then
    print "• ping: $1 is up"
  else
    print "• ping: no reply from $1 (can be fine, Windows often blocks ICMP)"
  fi
}

_dz_load() {
  emulate -L zsh
  local name=$1
  _dz_valid_name $name && _dz_box_read $DZ_ROOT/$name ||
    { _dz_err E202 "no box '$name' in $DZ_ROOT"; return 1 }
  local -a hosts=(${=reply[3]}) w targets=($reply[2])
  local ip=$reply[2] l v
  _dz_unset_hostvars
  typeset -gx BOX=$reply[1] INTERFACE=$DZ_IFACE
  # Extra hosts: $DC01_IP and so on, all IPs in $TARGETS; the active one is the target.
  for l in $_dz_bh; do
    w=(${=l})
    _dz_label_var $w[1]; v=$REPLY
    typeset -gx $v=$w[2]; _dz_hvars+=($v); targets+=($w[2])
    if [[ $w[1] == $_dz_ba ]]; then
      ip=$w[2]
      (( $#w > 2 )) && hosts=($w[3,-1])
    fi
  done
  typeset -gx TARGET_IP=$ip TARGET=$ip TARGETS="$targets" DZ_ACTIVE=$_dz_ba
  # $DOMAIN (The Hacker Recipes / Exegol) is the first hostname.
  if (( $#hosts )); then typeset -gx DOMAIN=$hosts[1]; else unset DOMAIN; fi
  _dz_attacker_refresh
  (( $+functions[_dz_creds_export] )) && _dz_creds_export
  unset DZ_DEADLINE
  _dz_clock_read $name && typeset -g DZ_DEADLINE="$reply[1] $reply[2]"
  mkdir -p ${DZ_STATE:h}
  print -r -- $name > $DZ_STATE
}

# _dz_new <name> <ip> [hosts]. hosts: separated by commas or spaces, 'none' clears them.
# An existing box keeps its hostnames unless you give new ones, and gets its IP (and
# note) updated.
_dz_new() {
  emulate -L zsh
  local name=$1 ip=$2 h
  local -a hosts=(${(s:,:)${3// /,}})
  _dz_valid_name $name || { _dz_err E203 "invalid name '$name'"; return 1 }
  _dz_valid_ip $ip || { _dz_err E204 "'$ip' is not an IPv4 address"; return 1 }
  [[ $hosts == none ]] || for h in $hosts; do
    _dz_valid_host $h || { _dz_err E205 "invalid hostname '$h'"; return 1 }
  done

  local dir=$DZ_ROOT/$name old_ip='' old_hosts=''
  _dz_box_read $dir && old_ip=$reply[2] old_hosts=$reply[3]
  local keep_active=$_dz_ba; local -a keep_hosts=("${_dz_bh[@]}")   # extra hosts stay
  if [[ $hosts == none ]]; then hosts=()
  elif (( ! $#hosts )); then hosts=(${=old_hosts})
  fi
  mkdir -p $dir/$^DZ_DIRS && _dz_box_write $dir $name $ip "$hosts" "$keep_active" "${keep_hosts[@]}" ||
    { _dz_err E206 "can't write $dir"; return 1 }

  # Note from the template (see _dz_note and _dz_template in status.zsh). An existing
  # note is never overwritten, only the IP in it.
  local note tpl n
  if note=$(_dz_note $name); then
    if [[ -f $note ]]; then
      n=$(_dz_note_ip $note "$old_ip" $ip)
      (( n )) && print "• note updated ($n× IP → $ip): ${note/#$HOME/~}" || print "• note unchanged: ${note/#$HOME/~}"
    elif tpl=$(_dz_template $4); then
      mkdir -p ${note:h}
      sed -e "s|{{name}}|$name|g" -e "s|{{title}}|$name|g" \
          -e "s|{{date}}|$(date +%F)|g" \
          -e "s|{{ip}}|$ip|g" \
          -e "s|{{hosts}}|${(j:, :)hosts}|g" \
          -e "s|^ip: *\$|ip: $ip|" \
          -e "s/^| \\\$TARGET_IP | | | |\$/| $ip | ${(j:, :)hosts} | | |/" \
          $tpl > $note
      _dz_note_ip $note '' $ip >/dev/null
      print "• note: ${note/#$HOME/~}"
    else
      _dz_warn W204 "no note template found, no note. Run the same dz -n again once it's there."
    fi
  fi

  # /etc/hosts: a box's line is tagged, so a new IP replaces the old line.
  if [[ "$hosts" != "$old_hosts" || ( -n $old_hosts && $ip != $old_ip ) ]]; then
    local re; _dz_hosts_re $name all; re=$REPLY
    for h in $hosts; do
      grep -vE "$re\$" $DZ_HOSTS 2>/dev/null | grep -qiE "[[:space:]]${h//./\\.}([[:space:]]|\$)" &&
        _dz_warn W203 "$h is already in $DZ_HOSTS outside dropzone"
    done
    _dz_hosts_set $name $ip "$hosts" &&
      if (( $#hosts )); then print "• $DZ_HOSTS: $ip $hosts (backup: $DZ_HOSTS.dz.bak)"
      elif [[ -n $old_hosts ]]; then print "• $DZ_HOSTS: line removed (backup: $DZ_HOSTS.dz.bak)"
      fi
  fi

  [[ $ip != $old_ip ]] && { _dz_vpn_check $ip; _dz_on DZ_PING && _dz_ping $ip }
  _dz_load $name && cd $dir
  print "• BOX=$BOX  TARGET_IP=$TARGET_IP  ATTACKER_IP=${ATTACKER_IP:-<$DZ_IFACE down>}${DOMAIN:+  DOMAIN=$DOMAIN}"
}

_dz_workon() {
  emulate -L zsh
  _dz_valid_name $1 || { _dz_err E203 "invalid name '$1'"; return 1 }
  if [[ ! -f $DZ_ROOT/$1/.dropzone && -f $DZ_ROOT/_archive/$1/.dropzone ]]; then
    _dz_unarchive $1 || return 1
  fi
  _dz_load $1 && cd $DZ_ROOT/$1 && _dz_vpn_check $TARGET_IP
}

# The $<HOST>_IP variables of the previous box.
_dz_unset_hostvars() {
  (( ${#_dz_hvars} )) && unset $_dz_hvars
  typeset -ga _dz_hvars=()
}

_dz_off() {
  _dz_unset_hostvars
  unset BOX TARGET_IP DOMAIN TARGET TARGETS DZ_ACTIVE INTERFACE ATTACKER_IP TARGET_USER PASSWORD NT_HASH CRED_DOMAIN DZ_DEADLINE
  (( $+functions[_dz_creds_unset_files] )) && _dz_creds_unset_files
  rm -f $DZ_STATE
}

# Remove a box. Folder to the trash (gio trash), with notes = vault the note to the
# Obsidian trash (.trash/ in the vault) if you want: both can be restored. With
# notes = folder the note is in the box folder and goes along with it.
# _dz_rm <name> [yes: 0/1] [note: ask/yes/no]
_dz_rm() {
  emulate -L zsh
  local name=$1 yes=${2:-0} note=${3:-ask} ans
  _dz_valid_name $name || { _dz_err E203 "invalid name '$name'"; return 1 }
  local dir=$DZ_ROOT/$name notefile=''
  [[ $DZ_NOTE_MODE == vault ]] && notefile=$(_dz_note $name)
  [[ -n $DZ_ROOT && -f $dir/.dropzone ]] || { _dz_err E202 "no box '$name' in $DZ_ROOT"; return 1 }

  if (( ! yes )); then
    [[ -t 0 ]] || { _dz_err E108 "no terminal to confirm, add -y"; return 1 }
    print "Remove box '$name'? ($(du -sh $dir | cut -f1), $(find $dir -type f | wc -l | tr -d ' ') files)"
    read -k 1 "ans?[y/N] "; print
    [[ $ans == [yY] ]] || { print "• cancelled"; return 1 }
  fi
  if [[ $note == ask && -n $notefile && -f $notefile ]]; then
    if [[ -t 0 ]]; then
      read -k 1 "ans?Also the box note in the vault? [y/N] "; print
      [[ $ans == [yY] ]] && note=yes || note=no
    else
      note=no
    fi
  fi

  [[ $PWD == $dir || $PWD == $dir/* ]] && cd ~
  if (( $+commands[gio] )) && gio trash $dir 2>/dev/null; then
    print "• folder to the trash: $dir"
  else
    rm -rf -- $dir && print "• folder deleted (no trash available): $dir"
  fi

  if [[ $note == yes && -n $notefile && -f $notefile ]]; then
    local trash=$DZ_VAULT/.trash dest
    mkdir -p $trash
    dest=$trash/$name.md
    [[ -e $dest ]] && dest=$trash/$name.$(date +%Y%m%d-%H%M%S).md
    mv $notefile $dest && print "• note to the Obsidian trash: $dest"
  elif [[ -n $notefile && -f $notefile ]]; then
    print "• note kept: $notefile"
  fi

  local re; _dz_hosts_re $name all; re=$REPLY
  if _dz_hosts_has $re; then
    _dz_hosts_del $re && print "• $DZ_HOSTS lines of $name removed (backup: $DZ_HOSTS.dz.bak)"
  fi

  if [[ $BOX == $name ]]; then
    _dz_off; print "• was the loaded box, unloaded"
  elif [[ -f $DZ_STATE && "$(<$DZ_STATE)" == $name ]]; then
    rm -f $DZ_STATE
  fi
}

# New terminal: load the last box (without cd). Called by dropzone.plugin.zsh once
# everything is loaded.
_dz_autoload() {
  _dz_on DZ_AUTOLOAD && [[ -f $DZ_STATE ]] && _dz_load "$(<$DZ_STATE)" 2>/dev/null
  return 0
}
