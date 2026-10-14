# cli: the dz command. Without arguments the menu, with options an action straight away.
# Runs as a function (not a script), so dz can cd and set variables in your own shell.

_dz_help() {
  emulate -L zsh
  local g=$'\e[1;38;5;46m' d=$'\e[38;5;246m' b=$'\e[1m' r=$'\e[0m'
  _dz_color || g='' d='' b='' r=''
  print -r -- "${g}dropzone${r} ${d}v$_dz_version · per-box tooling for Kali${r}

${b}Usage${r}
  dz              open the menu
  dz [options]    run an action straight away

${b}Options${r}
  -n <name>       new box (needs -ip)
  -ip <ip>        target IP; without -n it changes the IP of the loaded box
  -h <host,...>   hostnames for /etc/hosts; without -n it changes them, none clears
  -l <name>       load a box
  -v              view all boxes, --all includes the archive
  -i              show the loaded box
  -x              unload the box
  -o [name]       open the note (editor, or Obsidian with notes = vault)
  -d [name]       mark a box done
  -a <name>       archive a box (done, folder to _archive/)
  -f [user|root] <flag>
                  store a flag in the note (root flag = done); -f alone shows them
  -j <text>       add a line to the note's timeline; -j alone shows it
  -s [caption]    screenshot to evidence/, embedded in the timeline
  -c [user[:secret]] [source]
                  store or list creds (needs creds = yes)
  -r <name>       remove a box (to the trash)
  -y              no confirmation, with -r
  --note          also trash the note, with -r
  --keep-note     keep the note, with -r
  --config        edit the config (show: values in use, check: new settings)
  --update        update dropzone; your config, boxes and notes stay
  --version       version
  -h, --help      this help

${b}Examples${r}
  dz -n jacops -ip 10.129.42.190 -h dc01.jacops.htb,jacops.htb
  dz -ip 10.129.42.201
  dz -j found an NFS share with backups
  dz -s nfs share listing
  dz -c alex NFS
  dz -r jacops --note

${d}More: https://github.com/nickyjacobs/dropzone/blob/main/docs/commands.md${r}"
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
    printf '%s %-20s %-16s %-10s %s\n' $mark ${d:t} $reply[2] $st "$reply[3]"
  done
  [[ -z $all ]] && (( narch )) && print "  + $narch archived (dz -v --all)"
  return 0
}

# dz --update: pull the new version into the repo folder. Only the code changes: your
# config, templates, boxes and notes live outside it.
_dz_update() {
  emulate -L zsh
  local repo=$_dz_repo old=$_dz_version new
  [[ -d $repo/.git ]] || { print -u2 "dz: $repo is not a git clone, update it the way you installed it"; return 1 }
  [[ -z $(git -C $repo status --porcelain --untracked-files=no) ]] ||
    { print -u2 "dz: there are local changes in $repo, commit or stash them first"; return 1 }
  git -C $repo pull -q --ff-only || { print -u2 "dz: git pull failed, see the message above"; return 1 }
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
  [[ -n $BOX ]] || { print -u2 "no box loaded"; return 1 }
  _dz_box_read $DZ_ROOT/$BOX || { print -u2 "dz: box '$BOX' is gone (removed or archived?), dz -x"; return 1 }
  _dz_attacker_refresh
  local note=$(_dz_note $BOX)
  printf '%-10s %s\n' box $BOX target $TARGET_IP hosts "${reply[3]:--}" \
    attacker "${ATTACKER_IP:-$DZ_IFACE down}" status "$(_dz_status $BOX)" \
    folder $DZ_ROOT/$BOX note "$([[ -f $note ]] && print $note || print -)"
  [[ -n $TARGET_USER ]] && printf '%-10s %s\n' cred "$TARGET_USER (dz -c)"
  [[ -n $DZ_RECORDING ]] && printf '%-10s %s\n' recording "${DZ_RECORDING/#$HOME/~}"
  return 0
}

# Parser helpers for dz: one action per call, and options that take a value.
# They work on the locals of dz (dynamic scope).
_dz_act() {
  [[ -z $act || $act == $1 ]] || { print -u2 "dz: pick one action (-n, -l, -v, -i, -x, -o, -d, -a, -f, -j, -s, -c, -r)"; return 1 }
  act=$1
}
_dz_val() {
  [[ -n $2 && $2 != -* ]] || { print -u2 "dz: $1 needs a value (dz --help)"; return 1 }
}

# dz without arguments = menu; with options = an action straight away.
dz() {
  emulate -L zsh
  (( $# )) || { _dz_menu; return }
  # --help anywhere wins, so you can add it to any command (not inside the text of -j / -s).
  local -i stop=${@[(i)(-j|--journal|-s|--shot)]}
  (( ${${@[1,stop-1]}[(I)--help]} )) && { _dz_help; return 0 }

  local act='' name='' ip='' host='' yes=0 note=ask all='' cred='' credsrc='' fkind='' text=''
  while (( $# )); do
    case $1 in
      -n|--new)    _dz_val $1 "$2" && _dz_act new || return 1; name=$2; shift ;;
      -l|--load)   _dz_val $1 "$2" || return 1; name=$2; [[ -z $act ]] && act=load; shift ;;
      -r|--remove) _dz_val $1 "$2" && _dz_act rm || return 1; name=$2; shift ;;
      -ip|--ip)    _dz_val $1 "$2" || return 1; ip=$2; shift ;;
      -h|--host)   [[ -n $2 && $2 != -* ]] || { _dz_help; return 0 }   # -h alone = help
                   host=$2; shift ;;
      -v|--view)   _dz_act list || return 1 ;;
      -i|--info)   _dz_act info || return 1 ;;
      -x|--off)    _dz_act off || return 1 ;;
      -o|--open)   _dz_act open || return 1; [[ -n $2 && $2 != -* ]] && { name=$2; shift } ;;
      -d|--done)   _dz_act done || return 1; [[ -n $2 && $2 != -* ]] && { name=$2; shift } ;;
      -a|--archive) _dz_val $1 "$2" && _dz_act archive || return 1; name=$2; shift ;;
      --all)       all=1 ;;
      -f|--flag)   _dz_act flag || return 1
                   [[ $2 == (user|root) ]] && { fkind=$2; shift }
                   [[ -n $2 && $2 != -* ]] && { text=$2; shift } ;;
      # -j and -s take the rest of the line as text, quotes optional.
      -j|--journal) _dz_act journal || return 1; shift; text="$*"; break ;;
      -s|--shot)   _dz_act shot || return 1; shift; text="$*"; break ;;
      -c|--creds)  _dz_act creds || return 1
                   [[ -n $2 && $2 != -* ]] && { cred=$2; shift }
                   [[ -n $cred && -n $2 && $2 != -* ]] && { credsrc=$2; shift } ;;
      -y|--yes)    yes=1 ;;
      --note)      note=yes ;;
      --keep-note) note=no ;;
      --config)    case $2 in
                     show)  _dz_config_show ;;
                     check) _dz_config_check ;;
                     *)     _dz_config_edit ;;
                   esac; return ;;
      --update)    _dz_update; return ;;
      --version)   print "dropzone v$_dz_version"; return ;;
      *) print -u2 "dz: unknown option '$1' (dz --help)"; return 1 ;;
    esac
    shift
  done

  # -ip or -h without -n changes that box: the one from -l <name>, otherwise the loaded one.
  if [[ ( -n $ip || -n $host ) && $act != new ]]; then
    [[ -z $act || $act == load ]] || { print -u2 "dz: -ip and -h go with -n or -l"; return 1 }
    name=${name:-$BOX}
    [[ -n $name ]] || { print -u2 "dz: no box loaded, use -l <name> -ip <ip>"; return 1 }
    _dz_valid_name $name && _dz_box_read $DZ_ROOT/$name || { print -u2 "dz: no box '$name' in $DZ_ROOT"; return 1 }
    _dz_new $name ${ip:-$reply[2]} "$host"
    return
  fi

  case $act in
    new)  [[ -n $ip ]] || { print -u2 "dz: -n also needs -ip <ip>"; return 1 }
          _dz_new $name $ip "$host" ;;
    load) _dz_workon $name && _dz_info ;;
    rm)   _dz_rm $name $yes $note ;;
    list) _dz_list $all ;;
    open) _dz_open $name ;;
    done) _dz_done $name ;;
    archive) _dz_archive $name ;;
    creds) _dz_creds "$cred" "$credsrc" ;;
    flag) _dz_flag "$fkind" "$text" ;;
    journal) _dz_journal "$text" ;;
    shot) _dz_shot "$text" ;;
    info) _dz_info ;;
    off)  _dz_off && print "• box unloaded" ;;
    *)    print -u2 "dz: no action given (dz --help)"; return 1 ;;
  esac
}

# Tab completion: options, and box names after -l, -r, -o, -d and -a.
_dz_comp_boxes() {
  local -a b=($DZ_ROOT/*/.dropzone(Nn:h:t))
  _describe -t boxes box b
}
_dz_comp_all() {
  local -a b=($DZ_ROOT/*/.dropzone(Nn:h:t)) a=($DZ_ROOT/_archive/*/.dropzone(Nn:h:t))
  _describe -t boxes box b
  (( $#a )) && _describe -t archived 'archived box' a
}
_dz_complete() {
  _arguments \
    '(-l -r -v -i -x -o -d -a -c)-n[new box]:name:' \
    '-ip[target IP]:ip:' \
    '-h[hostnames, comma separated]:hostnames:' \
    '-l[load a box]:box:_dz_comp_all' \
    '(-n -l -v -i -x -o -d -a -c)-r[remove a box]:box:_dz_comp_boxes' \
    '-v[view boxes]' '--all[include the archive, with -v]' '-i[show the loaded box]' '-x[unload the box]' \
    '-c[store or list creds]::user\:secret:' \
    '-f[store or show a flag]::kind:(user root)' '-j[add to the timeline]:*::text:' '-s[take a screenshot]:*::caption:' \
    '-o[open the note]::box:_dz_comp_all' '-d[mark done]::box:_dz_comp_all' '-a[archive a box]:box:_dz_comp_boxes' \
    '-y[no confirmation]' '--note[also trash the note]' '--keep-note[keep the note]' \
    '--config[edit the config]::action:(show check)' '--update[update dropzone]' '--version[version]' '--help[help]'
}
(( $+functions[compdef] )) && compdef _dz_complete dz
