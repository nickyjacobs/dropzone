# status: box status (from the note's frontmatter), done, archive, open the note.
#
#   status: active / done lives in the note's frontmatter (see your Box-note template).
#   Archived boxes live in $DZ_ROOT/_archive/<name>; a box name can't start with '_'.

# Path of the note of box $1, by 'notes' in the config. Fails with notes = off.
#   folder  ~/boxes/<box>/notes.md (also in _archive/ for an archived box)
#   vault   <vault>/<vault_folder>/<box>.md
_dz_note() {
  case $DZ_NOTE_MODE in
    vault) print -r -- $DZ_VAULT/$DZ_NOTES/$1.md ;;
    off)   return 1 ;;
    *)     if [[ ! -d $DZ_ROOT/$1 && -d $DZ_ROOT/_archive/$1 ]]; then
             print -r -- $DZ_ROOT/_archive/$1/notes.md
           else
             print -r -- $DZ_ROOT/$1/notes.md
           fi ;;
  esac
}

# A template path as in the config: absolute, inside the vault with notes = vault, or
# inside ~/.config/dropzone. In $REPLY.
_dz_template_path() {
  if [[ $1 == /* ]]; then REPLY=$1
  elif [[ $DZ_NOTE_MODE == vault ]]; then REPLY=$DZ_VAULT/$1
  else REPLY=${DZ_CONFIG:h}/$1
  fi
}

# Template for new notes: 'template' from the config (absolute, or inside the vault with
# notes = vault, or inside ~/.config/dropzone), then ~/.config/dropzone/templates/box-note.md,
# then the one that ships with dropzone.
# With a name (dz -n ... --template exam): <name>.md, <name>-note.md or <Name>-note.md in
# ~/.config/dropzone/templates/, next to your 'template', then in dropzone's templates/.
# A name with a / or .md is a path, like 'template'.
_dz_template() {
  local t=$DZ_TEMPLATE c=${DZ_CONFIG:h} n=$1 d f
  if [[ -n $n && $n != */* && $n != *.md ]]; then
    local -a dirs=($c/templates)
    [[ -n $t ]] && { _dz_template_path $t; dirs+=(${REPLY:h}) }
    dirs+=($_dz_repo/templates)
    for d in $dirs; do
      for f in $n.md $n-note.md ${(C)n}-note.md; do
        [[ -f $d/$f ]] && { print -r -- $d/$f; return 0 }
      done
    done
    _dz_warn W205 "template '$n' not found in ${(j:, :)${dirs/#$HOME/~}}"; return 1
  fi
  [[ -n $n ]] && t=$n
  if [[ -n $t ]]; then
    _dz_template_path $t; t=$REPLY
    [[ -f $t ]] && { print -r -- $t; return 0 }
    _dz_warn W205 "template not found: $t"; return 1
  fi
  for t in $c/templates/box-note.md $_dz_repo/templates/box-note.md; do
    [[ -f $t ]] && { print -r -- $t; return 0 }
  done
  return 1
}

# Status of a box from the frontmatter, or '-' without a note or status line.
# bezig/af from older versions read as active/done.
_dz_status() {
  emulate -L zsh
  local note=$(_dz_note $1) s
  [[ -f $note ]] && s=$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} /^status:/{sub(/^status:[ \t]*/,""); print; exit}' $note)
  case $s in bezig) s=active ;; af) s=done ;; esac
  print -r -- ${s:--}
}

# _dz_set_status <box> <status>: set status and updated: in the frontmatter.
_dz_set_status() {
  local note=$(_dz_note $1)
  [[ -f $note ]] || { _dz_warn W206 "no note for $1, status not set"; return 0 }
  S=$2 TODAY=$(date +%F) perl -0777 -pi -e '
    if (/\A---\n(.*?)\n---\n/s) {
      my $fm = $1;
      $fm =~ s/^status:.*$/status: $ENV{S}/m or $fm .= "\nstatus: $ENV{S}";
      $fm =~ s/^updated:.*$/updated: $ENV{TODAY}/m;
      s/\A---\n.*?\n---\n/---\n$fm\n---\n/s;
    }' $note
}

# Box from the argument, otherwise the loaded box.
_dz_pick() {
  local name=${1:-$BOX}
  [[ -n $name ]] || { _dz_err E201 "no box loaded, give a name"; return 1 }
  _dz_valid_name $name || { _dz_err E203 "invalid name '$name'"; return 1 }
  REPLY=$name
}

# dz -d [name]: mark a box done.
_dz_done() {
  emulate -L zsh
  _dz_pick $1 || return 1
  [[ -f $DZ_ROOT/$REPLY/.dropzone || -f $DZ_ROOT/_archive/$REPLY/.dropzone ]] ||
    { _dz_err E202 "no box '$REPLY'"; return 1 }
  _dz_set_status $REPLY done && print "• $REPLY marked done (status: done)"
}

# dz -a <name>: done, folder to _archive/, /etc/hosts line removed. The note stays.
_dz_archive() {
  emulate -L zsh
  _dz_pick $1 || return 1
  local name=$REPLY src=$DZ_ROOT/$REPLY dst=$DZ_ROOT/_archive/$REPLY re
  [[ -f $src/.dropzone ]] || { _dz_err E202 "no box '$name' in $DZ_ROOT"; return 1 }
  [[ -e $dst ]] && { _dz_err E208 "$dst already exists"; return 1 }
  _dz_set_status $name done
  [[ $PWD == $src || $PWD == $src/* ]] && cd $DZ_ROOT
  mkdir -p ${dst:h} && mv $src $dst || return 1
  print "• $name archived: ${dst/#$HOME/~}"
  _dz_hosts_re $name all; re=$REPLY
  _dz_hosts_has $re && _dz_hosts_del $re && print "• $DZ_HOSTS lines of $name removed"
  if [[ $BOX == $name ]]; then _dz_off; print "• was the loaded box, unloaded"; fi
  return 0
}

# Move an archived box back (status active). Used by dz -l.
_dz_unarchive() {
  local src=$DZ_ROOT/_archive/$1 dst=$DZ_ROOT/$1
  [[ -f $src/.dropzone ]] || return 1
  if [[ -e $dst ]]; then
    _dz_err E209 "$1 is archived, but ${dst/#$HOME/~} exists and is not a box. Move it away, then dz -l $1 again."
    return 1
  fi
  mv $src $dst && _dz_set_status $1 active && print "• $1 restored from the archive (status: active)" || return 1
  # Its /etc/hosts lines went with the archive; put them back.
  _dz_hosts_all $1
}

# URL encoding for the obsidian:// link.
_dz_urlenc() {
  emulate -L zsh
  local LC_ALL=C s=$1 out='' c
  local -i i
  for (( i = 1; i <= $#s; i++ )); do
    c=$s[i]
    [[ $c == [A-Za-z0-9._~/-] ]] && out+=$c || out+=$(printf '%%%02X' "'$c")
  done
  print -r -- ${out//\//%2F}
}

# dz -o [name]: open the note. Vault: in Obsidian (obsidian:// link). Folder: in
# $VISUAL / $EDITOR, or the desktop's default app. Without either, print the path.
_dz_open() {
  emulate -L zsh
  _dz_pick $1 || return 1
  local name=$REPLY note
  note=$(_dz_note $name) || { _dz_err E401 "notes are off (notes = off in the config)"; return 1 }
  [[ -f $note ]] || { _dz_err E402 "no note for $name ($note)"; return 1 }
  local gui=0
  [[ -n $DISPLAY || -n $WAYLAND_DISPLAY ]] && (( $+commands[xdg-open] )) && gui=1

  if [[ $DZ_NOTE_MODE == vault ]]; then
    local uri="obsidian://open?vault=$(_dz_urlenc ${DZ_VAULT:t})&file=$(_dz_urlenc $DZ_NOTES/$name)"
    if (( gui )); then
      xdg-open $uri >/dev/null 2>&1 &!
      print "• opening the note in Obsidian: $name"
    else
      print "• no desktop session, open it yourself: $uri"
    fi
  elif [[ -n ${VISUAL:-$EDITOR} && -t 0 && -t 1 ]]; then
    ${=${VISUAL:-$EDITOR}} $note
  elif (( gui )); then
    xdg-open $note >/dev/null 2>&1 &!
    print "• opening the note: ${note/#$HOME/~}"
  else
    print "• note: $note"
  fi
}
