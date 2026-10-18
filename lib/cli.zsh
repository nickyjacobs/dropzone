# cli: the dz command. Without arguments the menu, with options an action straight away.
# Runs as a function (not a script), so dz can cd and set variables in your own shell.

_dz_help() {
  emulate -L zsh
  _dz_ui
  print -r -- "${_ug}dropzone${_ur} ${_ud}v$_dz_version · per-box tooling for Kali${_ur}"
  _dz_rule; _dz_head Usage
  _dz_row "dz" "open the menu"
  _dz_row "dz [options]" "run an action straight away"
  _dz_rule; _dz_head Boxes
  _dz_row "-n <name> -ip <ip>" "new box"
  _dz_row "  --template <name>" "another note template, like exam"
  _dz_row "--deadline [when]" "time limit: 10d, 48h or a date, none removes it"
  _dz_row "-l <name>" "load a box (an archived one comes back)"
  _dz_row "-v [--all]" "view all boxes, --all includes the archive"
  _dz_row "-i" "show the loaded box"
  _dz_row "-x" "unload the box"
  _dz_row "-d [name]" "mark a box done"
  _dz_row "-a <name>" "archive a box (done, folder to _archive/)"
  _dz_row "-r <name> [-y]" "remove a box (to the trash)"
  _dz_row "  --note / --keep-note" "also trash the note, or keep it, with -r"
  _dz_rule; _dz_head Target
  _dz_row "-ip <ip>" "new IP for the loaded box"
  _dz_row "-h <host,...>" "hostnames for /etc/hosts, none clears them"
  _dz_row "-t [host]" "hosts in the box: list, or make <host> the target"
  _dz_row "-t <host> -ip <ip>" "add or change a host (\$HOST_IP), --drop removes it"
  _dz_row "  --via <host>" "the host sits behind that pivot, none clears it"
  _dz_rule; _dz_head Notes
  _dz_row "-o [name]" "open the note"
  _dz_row "-j <text>" "line in the timeline, -j alone shows it"
  _dz_row "-s [caption]" "screenshot to evidence/, into the note"
  _dz_row "<cmd> | dz -e [caption]" "command output to evidence/, into the note"
  _dz_row "-f [user|root] <flag>" "flag into the note (root = done), -f shows them"
  _dz_row "-f <host> <flag>" "flag of a host in the box (dz -t), counted"
  _dz_row "-c [user[:secret]]" "store creds (needs creds = yes), -c lists them"
  _dz_row "-c [nr] --valid <hosts>" "where a cred works, into the note"
  _dz_row "-c --export" "users, passwords, hashes to loot/ for spraying"
  _dz_row "-p [file]" "open ports from your nmap output into the note"
  _dz_rule; _dz_head Tools
  _dz_row "serve [dir] [port]" "HTTP server + download commands with your IP"
  _dz_row "serve smb [dir]" "SMB share + copy commands"
  _dz_row "serve --via <host>" "for a host behind a pivot: ligolo listener + commands"
  _dz_row "-cp [what]" "copy to the clipboard: target, <host>, me, user, pass"
  _dz_rule; _dz_head Setup
  _dz_row "--config [show|check]" "edit the config, show it, list new settings"
  _dz_row "--update" "update dropzone, your config and boxes stay"
  _dz_row "--explain [code]" "what an error code (dz [E201] ...) means and the fix"
  _dz_row "--version" "version"
  _dz_row "-h, --help" "this help"
  _dz_rule; _dz_head Examples
  print -r -- "    ${_uk}dz -n jacops -ip 10.129.42.190 -h jacops.htb${_ur}"
  print -r -- "    ${_uk}dz -t dc01 -ip 10.129.42.191 -h dc01.jacops.htb${_ur}"
  print -r -- "    ${_uk}dz -j found an NFS share with backups${_ur}"
  print -r -- "    ${_uk}dz -s nfs share listing${_ur}"
  _dz_rule
  print -r -- "${_ud}More: https://github.com/nickyjacobs/dropzone/blob/main/docs/commands.md${_ur}"
}

# dz -v [--all]: boxes with IP, status and hostnames. --all also shows the archive.
_dz_list() {
  emulate -L zsh
  local d all=$1 mark st
  local -a dirs=($DZ_ROOT/*/.dropzone(Nn:h))
  [[ -n $all ]] && dirs+=($DZ_ROOT/_archive/*/.dropzone(Nn:h))
  local -a arch=($DZ_ROOT/_archive/*/.dropzone(N))
  local -i narch=$#arch
  (( $#dirs )) || { print "no boxes in $DZ_ROOT"; (( narch )) && print "$narch archived, see dz -v --all"; return 0 }
  for d in $dirs; do
    _dz_box_read $d || continue
    if [[ ${d:h:t} == _archive ]]; then mark=' ' st=archived
    else
      [[ ${d:t} == $BOX ]] && mark='▶' || mark=' '
      st=$(_dz_status ${d:t})
    fi
    printf '%s %-20s %-16s %-10s %s\n' $mark ${d:t} $reply[2] $st "$reply[3]${_dz_bh:+ (+$#_dz_bh hosts)}"
  done
  [[ -z $all ]] && (( narch )) && print "  + $narch archived (dz -v --all)"
  return 0
}

# dz --update: pull the new version into the repo folder. Only the code changes: your
# config, templates, boxes and notes live outside it.
_dz_update() {
  emulate -L zsh
  local repo=$_dz_repo old=$_dz_version new
  [[ -d $repo/.git ]] || { _dz_err E701 "$repo is not a git clone, update it the way you installed it"; return 1 }
  [[ -z $(git -C $repo status --porcelain --untracked-files=no) ]] ||
    { _dz_err E702 "there are local changes in $repo, commit or stash them first"; return 1 }
  git -C $repo pull -q --ff-only || { _dz_err E703 "git pull failed, see the message above"; return 1 }
  new=$(<$repo/VERSION)
  if [[ $new == $old ]]; then
    print "• dropzone v$old is up to date"
    return 0
  fi
  print "• dropzone v$old → v$new\n"
  awk -v old="$old" '/^## \[/ { v = $2; gsub(/[][]/, "", v); if (v == old) exit; on = (v != "Unreleased") } on' $repo/CHANGELOG.md
  print "• your config, templates, boxes and notes were not touched"
  print "• new settings? dz --config check · load the new version: exec zsh"
}

_dz_info() {
  emulate -L zsh
  [[ -n $BOX ]] || { _dz_err E201 "no box loaded"; return 1 }
  _dz_box_read $DZ_ROOT/$BOX || { _dz_err E207 "box '$BOX' is gone (removed or archived?), dz -x"; return 1 }
  _dz_attacker_refresh
  _dz_ui
  local note=$(_dz_note $BOX) l
  local -a extra=("${_dz_bh[@]}") w
  _dz_rule; _dz_head $BOX "$(_dz_status $BOX)"
  _dz_row target "$TARGET_IP${DZ_ACTIVE:+ ($DZ_ACTIVE)}" 10
  _dz_row hosts "${reply[3]:--}" 10
  _dz_row attacker "${ATTACKER_IP:-$DZ_IFACE down}" 10
  _dz_row folder "${DZ_ROOT/#$HOME/~}/$BOX" 10
  _dz_row note "$([[ -f $note ]] && print ${note/#$HOME/~} || print -)" 10
  [[ -n $TARGET_USER ]] && _dz_row cred "$TARGET_USER (dz -c)" 10
  _dz_clock_read $BOX && { _dz_clock_text $reply[1] $reply[2]; _dz_row clock "$REPLY" 10 }
  [[ -n $DZ_RECORDING ]] && _dz_row recording "${DZ_RECORDING/#$HOME/~}" 10
  if (( $#extra )); then
    _dz_rule; _dz_head Hosts "dz -t"
    _dz_row main "$reply[2]" 10
    for l in $extra; do
      w=(${=l}); _dz_label_var $w[1]; local hv=$REPLY
      _dz_via_get $w[1]
      _dz_row "${w[1]}" "$w[2]  \$$hv${w[3]:+  ${w[3,-1]}}${REPLY:+  via $REPLY}" 10
    done
  fi
  _dz_rule
  return 0
}

# Parser helpers for dz: one action per call, and options that take a value.
# They work on the locals of dz (dynamic scope).
_dz_act() {
  [[ -z $act || $act == $1 ]] || { _dz_err E103 "pick one action (-n, -l, -v, -i, -x, -t, -p, -cp, -o, -d, -a, -f, -j, -s, -e, -c, -r)"; return 1 }
  act=$1
}
_dz_val() {
  [[ -n $2 && $2 != -* ]] || { _dz_err E102 "$1 needs a value (dz --help)"; return 1 }
}

# dz without arguments = menu; with options = an action straight away.
dz() {
  emulate -L zsh
  (( $# )) || { _dz_menu; return }
  # Tools are words: dz serve.
  [[ $1 == serve ]] && { shift; _dz_serve "$@"; return }
  # --help anywhere wins, so you can add it to any command (not inside the text of -j / -s).
  local -i stop=${@[(i)(-j|--journal|-s|--shot|-e|--evidence)]}
  (( ${${@[1,stop-1]}[(I)--help]} )) && { _dz_help; return 0 }

  local act='' name='' ip='' host='' yes=0 note=ask all='' cred='' credsrc='' valid='' cexport='' tplname='' via='' deadline='' fkind='' text='' label='' drop='' file='' what=''
  while (( $# )); do
    case $1 in
      -n|--new)    _dz_val $1 "$2" && _dz_act new || return 1; name=$2; shift ;;
      -l|--load)   _dz_val $1 "$2" || return 1; name=$2; [[ -z $act ]] && act=load; shift ;;
      -r|--remove) _dz_val $1 "$2" && _dz_act rm || return 1; name=$2; shift ;;
      -ip|--ip)    _dz_val $1 "$2" || return 1; ip=$2; shift ;;
      -h|--host)   [[ -n $2 && $2 != -* ]] || { _dz_help; return 0 }   # -h alone = help
                   host=$2; shift ;;
      -v|--view)   _dz_act list || return 1 ;;
      -t|--target) _dz_act target || return 1; [[ -n $2 && $2 != -* ]] && { label=$2; shift } ;;
      --drop)      drop=1 ;;
      --via)       _dz_val $1 "$2" || return 1; via=$2; shift ;;
      -p|--ports)  _dz_act ports || return 1; [[ -n $2 && $2 != -* ]] && { file=$2; shift } ;;
      -cp|--copy)  _dz_act copy || return 1; [[ -n $2 && $2 != -* ]] && { what=$2; shift } ;;
      -i|--info)   _dz_act info || return 1 ;;
      -x|--off)    _dz_act off || return 1 ;;
      -o|--open)   _dz_act open || return 1; [[ -n $2 && $2 != -* ]] && { name=$2; shift } ;;
      -d|--done)   _dz_act done || return 1; [[ -n $2 && $2 != -* ]] && { name=$2; shift } ;;
      -a|--archive) _dz_val $1 "$2" && _dz_act archive || return 1; name=$2; shift ;;
      --all)       all=1 ;;
      -f|--flag)   _dz_act flag || return 1
                   # -f [user|root|<host>] [flag]: two words = kind + flag, one word = the flag.
                   if [[ -n $2 && $2 != -* && -n $3 && $3 != -* ]]; then fkind=$2 text=$3; shift 2
                   elif [[ $2 == (user|root) ]]; then fkind=$2; shift
                   elif [[ -n $2 && $2 != -* ]]; then text=$2; shift
                   fi ;;
      # -j and -s take the rest of the line as text, quotes optional.
      -j|--journal) _dz_act journal || return 1; shift; text="$*"; break ;;
      -s|--shot)   _dz_act shot || return 1; shift; text="$*"; break ;;
      -e|--evidence) _dz_act evidence || return 1; shift; text="$*"; break ;;
      -c|--creds)  _dz_act creds || return 1
                   [[ -n $2 && $2 != -* ]] && { cred=$2; shift }
                   [[ -n $cred && -n $2 && $2 != -* ]] && { credsrc=$2; shift } ;;
      --valid)     _dz_val $1 "$2" || return 1; valid=$2; shift ;;
      --export)    cexport=1 ;;
      --template)  _dz_val $1 "$2" || return 1; tplname=$2; shift ;;
      --deadline)  if [[ -n $2 && $2 != -* ]]; then deadline=$2; shift; else deadline=show; fi ;;
      -y|--yes)    yes=1 ;;
      --note)      note=yes ;;
      --keep-note) note=no ;;
      --config)    case $2 in
                     show)  _dz_config_show ;;
                     check) _dz_config_check ;;
                     *)     _dz_config_edit ;;
                   esac; return ;;
      --update)    _dz_update; return ;;
      --explain)   _dz_explain "$2"; return ;;
      --version)   print "dropzone v$_dz_version"; return ;;
      *) _dz_err E101 "unknown option '$1' (dz --help)"; return 1 ;;
    esac
    shift
  done

  # -ip or -h without -n changes that box: the one from -l <name>, otherwise the loaded one.
  if [[ ( -n $ip || -n $host ) && $act != (new|target) ]]; then
    [[ -z $act || $act == load ]] || { _dz_err E105 "-ip and -h go with -n or -l"; return 1 }
    name=${name:-$BOX}
    [[ -n $name ]] || { _dz_err E201 "no box loaded, use -l <name> -ip <ip>"; return 1 }
    _dz_valid_name $name && _dz_box_read $DZ_ROOT/$name || { _dz_err E202 "no box '$name' in $DZ_ROOT"; return 1 }
    _dz_new $name ${ip:-$reply[2]} "$host" "$tplname"
    return
  fi

  [[ -z $act && -n $deadline ]] && act=deadline
  case $act in
    new)  [[ -n $ip ]] || { _dz_err E106 "-n also needs -ip <ip>"; return 1 }
          _dz_new $name $ip "$host" "$tplname" || return
          [[ -z $deadline ]] || _dz_deadline "$deadline" ;;
    deadline) _dz_deadline "$deadline" ;;
    load) _dz_workon $name && _dz_info ;;
    rm)   _dz_rm $name $yes $note ;;
    list) _dz_list $all ;;
    open) _dz_open $name ;;
    done) _dz_done $name ;;
    archive) _dz_archive $name ;;
    creds) _dz_creds "$cred" "$credsrc" "$valid" "$cexport" ;;
    flag) _dz_flag "$fkind" "$text" ;;
    journal) _dz_journal "$text" ;;
    shot) _dz_shot "$text" ;;
    evidence) _dz_evidence "$text" ;;
    info) _dz_info ;;
    target) _dz_target "$label" "$ip" "$host" "$drop" "$via" ;;
    ports) _dz_ports "$file" ;;
    copy)  _dz_copy "$what" ;;
    off)  _dz_off && print "• box unloaded" ;;
    *)    _dz_err E104 "no action given (dz --help)"; return 1 ;;
  esac
}

# Tab completion: options, and box names after -l, -r, -o, -d and -a.
_dz_comp_boxes() {
  local -a b=($DZ_ROOT/*/.dropzone(Nn:h:t))
  _describe -t boxes box b
}
_dz_comp_copy() {
  local -a w=(target me domain targets user pass hash)
  [[ -n $BOX ]] && _dz_box_read $DZ_ROOT/$BOX 2>/dev/null && w+=($BOX ${_dz_bh%% *})
  _describe -t what what w
}
_dz_comp_hosts() {
  local -a h=() l
  [[ -n $BOX ]] && _dz_box_read $DZ_ROOT/$BOX 2>/dev/null && h=($BOX ${_dz_bh%% *})
  _describe -t hosts host h
}
_dz_comp_codes() {
  local -a c=() k
  for k in ${(ko)_dz_err_title}; do c+=("$k:$_dz_err_title[$k]"); done
  _describe -t codes code c
}
_dz_comp_flag() {
  local -a k=(user root)
  [[ -n $BOX ]] && _dz_box_read $DZ_ROOT/$BOX 2>/dev/null && (( $#_dz_bh )) && k+=($BOX ${_dz_bh%% *})
  _describe -t kinds kind k
}
_dz_comp_all() {
  local -a b=($DZ_ROOT/*/.dropzone(Nn:h:t)) a=($DZ_ROOT/_archive/*/.dropzone(Nn:h:t))
  _describe -t boxes box b
  (( $#a )) && _describe -t archived 'archived box' a
}
_dz_complete() {
  _arguments \
    '(-l -r -v -i -x -o -d -a -c)-n[new box]:name:' \
    '-ip[target IP]:ip:' '--template[note template for -n]:template:(exam)' '--deadline[time limit of the box]::when:(10d 24h none)' \
    '-h[hostnames, comma separated]:hostnames:' \
    '-l[load a box]:box:_dz_comp_all' \
    '(-n -l -v -i -x -o -d -a -c)-r[remove a box]:box:_dz_comp_boxes' \
    '-v[view boxes]' '--all[include the archive, with -v]' '-i[show the loaded box]' '-x[unload the box]' \
    '-t[hosts in the box]::host:_dz_comp_hosts' '--drop[remove the host, with -t]' '--via[pivot of the host, with -t]:pivot:_dz_comp_hosts' \
    '-p[nmap output into the note]::nmap output:_files -g "*.(xml|gnmap)"' \
    '-cp[copy to the clipboard]::what:_dz_comp_copy' \
    '-c[store or list creds]::user\:secret:' '--valid[hosts where the cred works, with -c]:hosts:_dz_comp_hosts' '--export[users, passwords and hashes to loot/, with -c]' \
    '-f[store or show a flag]::kind:_dz_comp_flag' '-j[add to the timeline]:*::text:' '-s[take a screenshot]:*::caption:' '-e[save piped output as evidence]:*::caption:' \
    '-o[open the note]::box:_dz_comp_all' '-d[mark done]::box:_dz_comp_all' '-a[archive a box]:box:_dz_comp_boxes' \
    '-y[no confirmation]' '--note[also trash the note]' '--keep-note[keep the note]' \
    '--config[edit the config]::action:(show check)' '--update[update dropzone]' '--explain[explain an error code]::code:_dz_comp_codes' '--version[version]' '--help[help]'
}
(( $+functions[compdef] )) && compdef _dz_complete dz
