# config: ~/.config/dropzone/config (see config.example and docs/config.md).
# Format: 'key = value', comments with #, [sections] only for readability.
# The file is read, never run. A missing line means the default.

DZ_CONFIG=${DZ_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dropzone/config}

_dz_config_defaults() {
  DZ_ROOT=$HOME/boxes
  DZ_NOTE_MODE=           # folder, vault or off; empty = vault when 'vault' is set, else folder
  DZ_VAULT=
  DZ_NOTES=Boxes          # note folder inside the vault
  DZ_TEMPLATE=
  DZ_DIRS=(scans loot exploits evidence logs)
  DZ_IFACE=tun0
  DZ_PIVOT=('ligolo*')    # interfaces of a pivot tunnel, the VPN check accepts routes through them
  DZ_AUTOLOAD=yes
  DZ_PING=yes
  DZ_VPNCHECK=yes
  DZ_PROMPT=yes
  DZ_CREDS=no
  DZ_SYSREPTOR=no
  DZ_LOG_COMMANDS=yes
  DZ_LOG_OUTPUT=no
  DZ_TIMELINE=Timeline
  DZ_ADD_SECTIONS=yes     # add a missing Timeline, Flags, To do or Findings section to the note
  DZ_FLAG_GOAL=0          # flags to find in a box with more hosts (14 on the CPTS exam), 0 = no count
  DZ_SHOT=auto
  DZ_ATTACH=Boxes/attachments
  typeset -ga _dz_cfg_old=()   # old key forms still in use (for --config check)
  DZ_ART=
  DZ_ANIMATE=yes
  : ${DZ_STATE:=$HOME/.config/dropzone/current}
  : ${DZ_HOSTS:=/etc/hosts}
}

# Read the config over the defaults. Report mistakes with a line number and keep
# reading the rest of the file.
_dz_config_load() {
  emulate -L zsh -o extended_glob
  _dz_config_defaults
  typeset -gA _dz_cfg_src=()      # keys that come from the config (for --config show)
  [[ -r $DZ_CONFIG ]] || { _dz_config_resolve; return 0 }

  local line key val
  local -i n=0
  _dz_cfg_err() { _dz_warn W701 "config line $n: $1 (line skipped)" }
  while IFS= read -r line || [[ -n $line ]]; do
    (( n++ ))
    line=${line%%[[:space:]]#\#*}                       # strip comment
    line=${${line##[[:space:]]#}%%[[:space:]]#}         # strip spaces
    [[ -z $line || $line == \[*\] ]] && continue        # empty or [section]
    [[ $line == *=* ]] || { _dz_cfg_err "'$line' is not 'key = value'"; continue }
    key=${${line%%=*}%%[[:space:]]#}
    val=${${line#*=}##[[:space:]]#}
    [[ $val == '~'* ]] && val=$HOME${val#\~}
    [[ -z $val ]] && continue                           # empty = default

    case $key in
      boxes)
        [[ $val == /* ]] || { _dz_cfg_err "boxes must be an absolute path, not '$val'"; continue }
        DZ_ROOT=$val ;;
      vault)    DZ_VAULT=$val ;;
      notes)
        if [[ $val == (folder|vault|off) ]]; then DZ_NOTE_MODE=$val
        else
          # Older configs used 'notes' for the note folder inside the vault.
          DZ_NOTE_MODE=vault DZ_NOTES=$val
          _dz_cfg_old+=("line $n: 'notes = $val' is the old form, now: notes = vault + vault_folder = $val")
        fi ;;
      vault_folder) DZ_NOTES=$val ;;
      template) DZ_TEMPLATE=$val ;;
      folders)  DZ_DIRS=(${=val}) ;;
      iface)    DZ_IFACE=$val ;;
      pivot)    [[ $val == none ]] && DZ_PIVOT=() || DZ_PIVOT=(${=val}) ;;
      timeline) DZ_TIMELINE=$val ;;
      flag_goal)
        [[ $val == <0-> ]] || { _dz_cfg_err "flag_goal must be a number, not '$val'"; continue }
        DZ_FLAG_GOAL=$val ;;
      attachments) DZ_ATTACH=$val ;;
      screenshot)
        [[ $val == (auto|xfce4-screenshooter|flameshot|gnome-screenshot|spectacle|grim|import) ]] ||
          { _dz_cfg_err "screenshot must be auto, xfce4-screenshooter, flameshot, gnome-screenshot, spectacle, grim or import, not '$val'"; continue }
        DZ_SHOT=$val ;;
      autoload|animate|ping|prompt|commands|output|creds|vpncheck|sysreptor|add_sections)
        [[ ${(L)val} == (yes|no|true|false|on|off) ]] ||
          { _dz_cfg_err "$key must be yes or no, not '$val'"; continue }
        case $key in
          commands) DZ_LOG_COMMANDS=$val ;;
          output)   DZ_LOG_OUTPUT=$val ;;
          *)        typeset -g DZ_${(U)key}=$val ;;
        esac ;;
      art)
        if [[ $val == random ]]; then DZ_ART=
        elif [[ $val == <1-> ]] && (( val <= _dz_art_count )); then DZ_ART=$val
        else _dz_cfg_err "art must be 1 to $_dz_art_count or random, not '$val'"; continue
        fi ;;
      *) _dz_cfg_err "unknown setting '$key'"; continue ;;
    esac
    _dz_cfg_src[$key]=config
  done < $DZ_CONFIG
  unfunction _dz_cfg_err
  _dz_config_resolve
}

# Settings that depend on each other, after reading.
_dz_config_resolve() {
  [[ -n $DZ_NOTE_MODE ]] || { [[ -n $DZ_VAULT ]] && DZ_NOTE_MODE=vault || DZ_NOTE_MODE=folder }
  if [[ $DZ_NOTE_MODE == vault && -z $DZ_VAULT ]]; then
    _dz_warn W702 "notes = vault needs 'vault = /path/to/your/vault' in the config, using notes = folder"
    DZ_NOTE_MODE=folder
  fi
  return 0
}

# Colour on fd $1 (default stdout)? Not when piped, with NO_COLOR set, or TERM=dumb.
_dz_color() { [[ -t ${1:-1} && -z $NO_COLOR && $TERM != dumb ]] }

# dz --config show: the values in use now, and whether each comes from your config.
_dz_config_show() {
  emulate -L zsh
  local k v
  _dz_ui
  print -r -- "${_ug}dropzone config${_ur} ${_ud}${DZ_CONFIG/#$HOME/~}${_ur}"
  [[ -r $DZ_CONFIG ]] || print -r -- "${_ud}(no config file, everything is default)${_ur}"
  local -a rows=(
    paths boxes "${DZ_ROOT/#$HOME/~}"
    box folders "$DZ_DIRS"  box iface "$DZ_IFACE"  box pivot "${DZ_PIVOT:-none}"
    box autoload "$DZ_AUTOLOAD"  box ping "$DZ_PING"  box vpncheck "$DZ_VPNCHECK"  box prompt "$DZ_PROMPT"
    log commands "$DZ_LOG_COMMANDS"  log output "$DZ_LOG_OUTPUT"
    notes notes "$DZ_NOTE_MODE"  notes template "${${DZ_TEMPLATE:-$(_dz_template 2>/dev/null)}/#$HOME/~}"
    notes vault "${DZ_VAULT:--}"  notes vault_folder "$DZ_NOTES"  notes attachments "$DZ_ATTACH"
    notes timeline "$DZ_TIMELINE"  notes add_sections "$DZ_ADD_SECTIONS"  notes flag_goal "$DZ_FLAG_GOAL"  notes screenshot "$DZ_SHOT"
    creds creds "$DZ_CREDS"
    sysreptor sysreptor "$DZ_SYSREPTOR"
    menu art "${DZ_ART:-random}"  menu animate "$DZ_ANIMATE")
  local sec last=''
  for sec k v in $rows; do
    [[ $sec != $last ]] && { _dz_rule; _dz_head $sec; last=$sec }
    printf -v v '%-42s' "$v"
    _dz_row $k "$v ${_ud}${_dz_cfg_src[$k]:-default}${_ur}" 13
  done
  _dz_rule
}

# dz --config check: settings from config.example that aren't in your config yet (the
# default applies to them), and old key forms that still work but have a new name.
_dz_config_check() {
  emulate -L zsh -o extended_glob
  local line key sec='' com=''
  local -A have
  if [[ -r $DZ_CONFIG ]]; then
    while IFS= read -r line || [[ -n $line ]]; do
      line=${${line%%[[:space:]]#\#*}##[[:space:]]#}
      [[ $line == *=* ]] && have[${${line%%=*}%%[[:space:]]#}]=1
    done < $DZ_CONFIG
  fi
  local -a out=()
  while IFS= read -r line || [[ -n $line ]]; do
    case $line in
      \[*\]) sec=$line ;;
      '#'*)   [[ -z $com ]] && com=${line#\#[[:space:]]#} ;;
      [a-z]*=*)
        key=${${line%%=*}%%[[:space:]]#}
        (( $+have[$key] )) || out+=("$sec ${${line%%=*}%%[[:space:]]#} =${line#*=}"$'\t'"$com")
        com='' ;;
      *) com='' ;;
    esac
  done < $_dz_repo/config.example
  _dz_ui
  if (( $#out )); then
    _dz_rule; _dz_head "Not in your config" "the default applies, add a line to change it"
    for line in $out; do
      _dz_row "${line%%$'\t'*}" "${_ud}${line#*$'\t'}${_ur}" 46
    done
  else
    print "• your config has every setting"
  fi
  if (( $#_dz_cfg_old )); then
    _dz_rule; _dz_head "Old forms" "still working"
    print -rl -- "    "$^_dz_cfg_old
  fi
  (( $#out + $#_dz_cfg_old )) && _dz_rule
  return 0
}

# Is a yes/no setting on? $1 = variable name.
_dz_on() { [[ ${(L)${(P)1}} == (true|yes|on|1) ]] }

# dz --config: open in your editor (created from config.example if missing),
# then load it again straight away. $VISUAL/$EDITOR may contain options ('code -w').
_dz_config_edit() {
  emulate -L zsh
  if [[ ! -f $DZ_CONFIG ]]; then
    mkdir -p ${DZ_CONFIG:h} && cp $_dz_repo/config.example $DZ_CONFIG &&
      print "• config created: $DZ_CONFIG"
  fi
  ${=${VISUAL:-${EDITOR:-nano}}} $DZ_CONFIG
  _dz_config_load && print "• config reloaded"
}

_dz_config_load
