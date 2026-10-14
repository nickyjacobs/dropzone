# notes: flags, timeline and screenshots in the note of the loaded box.
#
#   dz -f [user|root] <flag>   flag into the note's Flags section (root flag = done)
#   dz -j <text>               timestamped line in the timeline section
#   dz -s [caption]            screenshot to evidence/, embedded in the timeline
#
# The timeline section is '## <timeline>' (config, default Timeline); dz adds it before
# '## Flags' when the note doesn't have one yet. Flags work in two layouts:
#   - **User flag:** <flag>                    (the template that ships with dropzone)
#   **User flag** + '> [!success]- Flag' + '> <flag>'   (Obsidian callout, see examples/)

# Note of the loaded box in $REPLY, or fail with a message.
_dz_note_need() {
  [[ -n $BOX ]] || { print -u2 "dz: no box loaded"; return 1 }
  REPLY=$(_dz_note $BOX) || { print -u2 "dz: notes are off (notes = off in the config)"; return 1 }
  [[ -f $REPLY ]] || { print -u2 "dz: no note for $BOX ($REPLY)"; return 1 }
}

# _dz_timeline_add <note> <text>: '- <date> <time> · <text>' at the end of the timeline
# section. Extra lines in <text> (an embed) stay under the entry.
_dz_timeline_add() {
  local ts; strftime -s ts '%F %H:%M' $EPOCHSECONDS
  HEAD=$DZ_TIMELINE ENTRY="- $ts · $2" TODAY=${ts% *} perl -0777 -pi -e '
    my $h = quotemeta $ENV{HEAD};
    unless (/^## $h[ \t]*$/m) {
      s/^(## Flags[ \t]*)$/## $ENV{HEAD}\n\n$1/m
        or do { $_ .= "\n" unless /\n\z/; $_ .= "\n## $ENV{HEAD}\n\n" };
    }
    s{(^## $h[ \t]*\n)(.*?)(?=^## |\z)}{
      my ($head, $body) = ($1, $2);
      $body =~ s/^-[ \t]*\n//mg;               # empty template bullet
      $body =~ s/\A\s+//; $body =~ s/\s+\z//;
      $head . "\n" . ($body eq "" ? "" : "$body\n") . "$ENV{ENTRY}\n\n"
    }sme;
    s/^updated: .*$/updated: $ENV{TODAY}/m;
  ' $1
}

# Last $2 timeline entries of note $1.
_dz_timeline_show() {
  HEAD=$DZ_TIMELINE N=${2:-10} perl -0777 -ne '
    my $h = quotemeta $ENV{HEAD};
    if (/^## $h[ \t]*\n(.*?)(?=^## |\z)/sm) {
      my @e = grep { /^- \S/ } split /\n/, $1;
      print "$_\n" for @e[($#e - $ENV{N} + 1 < 0 ? 0 : $#e - $ENV{N} + 1) .. $#e];
    }' $1
}

# Flags of note $1: reply=(user root), '' when empty.
_dz_flags_get() {
  local out=$(perl -0777 -ne '
    for my $k ("User", "Root") {
      my ($v) = /^\*\*$k flag\*\*[ \t]*\n> \[!success\][^\n]*\n>[ \t]*([^\n]*)/m;
      ($v) = /^- \*\*$k flag:\*\*[ \t]*([^\n]*)/m unless defined $v;
      $v =~ s/\s+\z// if defined $v;
      print +($v // ""), "\t";
    }' $1)
  reply=("${(@ps:\t:)out}")
  reply=("$reply[1]" "$reply[2]")
}

# _dz_flags_set <note> <User|Root> <flag>: into the empty callout; adds the Flags
# section when the note has none.
_dz_flags_set() {
  K=$2 FLAG=$3 perl -0777 -pi -e '
    unless (/^\*\*User flag\*\*/m || /^- \*\*User flag:\*\*/m) {
      $_ .= "\n" unless /\n\z/;
      $_ .= "\n## Flags\n\n- **User flag:** \n- **Root flag:** \n";
    }
    s/(^\*\*$ENV{K} flag\*\*[ \t]*\n> \[!success\][^\n]*\n)>[ \t]*\n/$1> $ENV{FLAG}\n/m
      or s/^(- \*\*$ENV{K} flag:\*\*)[ \t]*$/$1 $ENV{FLAG}/m;
  ' $1
}

# dz -f [user|root] [flag]
_dz_flag() {
  emulate -L zsh
  local kind=$1 flag=$2 note
  _dz_note_need || return 1; note=$REPLY
  _dz_flags_get $note
  local user=$reply[1] root=$reply[2]

  if [[ -z $flag ]]; then                                # show
    printf '%-5s %s\n' user "${user:--}" root "${root:--}"
    return 0
  fi
  [[ $flag == *[[:space:]]* ]] && { print -u2 "dz: a flag has no spaces"; return 1 }
  if [[ -z $kind ]]; then
    if [[ -z $user ]]; then kind=user
    elif [[ -z $root ]]; then kind=root
    else print -u2 "dz: $BOX already has both flags, see dz -f"; return 1
    fi
  fi
  local -i idx; [[ $kind == user ]] && idx=1 || idx=2
  local cur=$reply[idx]
  [[ -n $cur ]] && { print -u2 "dz: $BOX already has a $kind flag ($cur). Change it in the note."; return 1 }
  [[ $flag =~ '^[0-9a-f]{32}$' ]] || print -u2 "• note: '$flag' is not the usual HTB flag (32 hex), stored anyway"

  _dz_flags_set $note ${(C)kind} $flag
  _dz_flags_get $note
  [[ $reply[idx] == $flag ]] ||
    { print -u2 "dz: couldn't place the flag in $note (Flags section changed?)"; return 1 }
  _dz_timeline_add $note "$kind flag"
  print "• $kind flag stored in the note"
  if [[ $kind == root ]]; then
    _dz_set_status $BOX done && print "• $BOX marked done (status: done)"
  fi
}

# dz -j [text]: add to the timeline, or show its last entries.
_dz_journal() {
  emulate -L zsh
  local note
  _dz_note_need || return 1; note=$REPLY
  if [[ -z $1 ]]; then
    local out=$(_dz_timeline_show $note 10)
    [[ -n $out ]] && print -r -- $out || print "no timeline entries for $BOX yet"
    return 0
  fi
  _dz_timeline_add $note "${1//$'\n'/ }" && print "• added to the timeline of $BOX"
}

# Screenshot tool: 'screenshot' from the config, or the first one found.
_dz_shot_tool() {
  local t
  if [[ $DZ_SHOT != auto ]]; then
    (( $+commands[$DZ_SHOT] )) && { REPLY=$DZ_SHOT; return 0 }
    print -u2 "dz: screenshot tool '$DZ_SHOT' not found"; return 1
  fi
  for t in xfce4-screenshooter flameshot gnome-screenshot import; do
    (( $+commands[$t] )) && { REPLY=$t; return 0 }
  done
  print -u2 "dz: no screenshot tool found (xfce4-screenshooter, flameshot, gnome-screenshot or import)"
  return 1
}

# _dz_shot_take <tool> <file>: select a region and save it as PNG.
_dz_shot_take() {
  case $1 in
    xfce4-screenshooter) xfce4-screenshooter -r -s $2 ;;
    flameshot)           flameshot gui -r > $2 ;;
    gnome-screenshot)    gnome-screenshot -a -f $2 ;;
    import)              import $2 ;;
  esac 2>/dev/null
}

# dz -s [caption]: screenshot to evidence/, a copy in the vault, embedded in the timeline.
_dz_shot() {
  emulate -L zsh -o extended_glob
  local caption=${1//$'\n'/ } note='' tool
  if [[ $DZ_NOTE_MODE == off ]]; then
    [[ -n $BOX ]] || { print -u2 "dz: no box loaded"; return 1 }
  else
    _dz_note_need || return 1; note=$REPLY
  fi
  [[ -n $DISPLAY || -n $WAYLAND_DISPLAY ]] || { print -u2 "dz: no desktop session for a screenshot"; return 1 }
  _dz_shot_tool || return 1; tool=$REPLY

  local ts slug name
  strftime -s ts '%F_%H%M%S' $EPOCHSECONDS
  slug=${${${(L)caption}//[^a-z0-9]##/-}##-}; slug=${${slug[1,40]}%%-}
  name=${BOX}_$ts${slug:+_$slug}.png
  local ev=$DZ_ROOT/$BOX/evidence
  mkdir -p $ev || return 1

  print "• select a region (Esc cancels)"
  _dz_shot_take $tool $ev/$name
  [[ -s $ev/$name ]] || { rm -f $ev/$name; print "• no screenshot taken"; return 1 }
  # The embed: next to the note (folder), or a copy inside the vault (Obsidian only
  # shows images that are in the vault). notes = off: only evidence/.
  local embed
  if [[ $DZ_NOTE_MODE == vault ]]; then
    mkdir -p $DZ_VAULT/$DZ_ATTACH/$BOX && cp $ev/$name $DZ_VAULT/$DZ_ATTACH/$BOX/$name || return 1
    embed="![[$DZ_ATTACH/$BOX/$name]]"
  else
    embed="![${${caption//[\[\]]/}:-screenshot}](evidence/$name)"
  fi
  if [[ -z $note ]]; then
    print "• screenshot: ${ev/#$HOME/~}/$name"
    return 0
  fi
  _dz_timeline_add $note "screenshot${caption:+: $caption}"$'\n'"  $embed"
  print "• screenshot: ${ev/#$HOME/~}/$name (in the note too)"
}
