# notes: flags, timeline and screenshots in the note of the loaded box.
#
#   dz -f [user|root] <flag>   flag into the note's Flags section (root flag = done)
#   dz -f <host> <flag>        flag of a host, as a line in the Flags section (exams, AD sets)
#   dz -j <text>               timestamped line in the timeline section
#   dz -s [caption]            screenshot to evidence/, embedded in the timeline
#   <cmd> | dz -e [caption]    command output to evidence/, with the command, in the timeline
#                              (both go under the active finding instead, see findings.zsh)
#   dz -g <term> [--all]       search the notes of every box (--all: the archive too)
#
# The timeline section is '## <timeline>' (config, default Timeline); dz adds it before
# '## Flags' when the note doesn't have one yet (not with 'add_sections = no'). Flags work in two layouts:
#   - **User flag:** <flag>                    (the template that ships with dropzone)
#   **User flag** + '> [!success]- Flag' + '> <flag>'   (Obsidian callout, see examples/)
# A box with more hosts (dz -t), or a note without those slots, keeps a list instead: '- <date> <time> · <host> · <flag>',
# with a count against 'flag_goal' from the config. It is never marked done by a flag.

# _dz_note_has <note> <heading>: does the note have '## <heading>'?
_dz_note_has() { H=$2 perl -0777 -ne 'exit(/^## \Q$ENV{H}\E[ \t]*$/m ? 0 : 1)' $1 }

# _dz_section_ensure <note> <heading> [before...]: add '## <heading>' when the note doesn't
# have it, right before the first of the [before] headings it does have, else at the end.
# With 'add_sections = no' dz never adds a section: it fails, and the caller reports it.
_dz_section_ensure() {
  local note=$1 head=$2; shift 2
  _dz_note_has $note $head && return 0
  _dz_on DZ_ADD_SECTIONS || return 1
  HEAD=$head BEFORE=${(pj:\n:)@} perl -0777 -pi -e '
    my $done = 0;
    for my $b (grep { length } split /\n/, $ENV{BEFORE}) {
      $done = s/^(## \Q$b\E[ \t]*)$/## $ENV{HEAD}\n\n$1/m and last;
    }
    unless ($done) { $_ .= "\n" unless /\n\z/; $_ .= "\n## $ENV{HEAD}\n\n" }
  ' $note
}

# Note of the loaded box in $REPLY, or fail with a message.
_dz_note_need() {
  [[ -n $BOX ]] || { _dz_err E201 "no box loaded"; return 1 }
  REPLY=$(_dz_note $BOX) || { _dz_err E401 "notes are off (notes = off in the config)"; return 1 }
  [[ -f $REPLY ]] || { _dz_err E402 "no note for $BOX ($REPLY)"; return 1 }
}

# _dz_timeline_add <note> <text>: '- <date> <time> · <text>' at the end of the timeline
# section. Extra lines in <text> (an embed) stay under the entry.
_dz_timeline_add() {
  local ts; strftime -s ts '%F %H:%M' $EPOCHSECONDS
  _dz_section_ensure $1 "$DZ_TIMELINE" Flags ||
    { _dz_warn W403 "the note has no '## $DZ_TIMELINE' (add_sections = no), line not written: ${2%%$'\n'*}"; return 1 }
  HEAD=$DZ_TIMELINE ENTRY="- $ts · $2" TODAY=${ts% *} perl -0777 -pi -e '
    my $h = quotemeta $ENV{HEAD};
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
  if ! grep -qE '^(- )?\*\*User flag' $1; then
    _dz_section_ensure $1 Flags || { _dz_err E413 "the note has no '## Flags' section (add_sections = no)"; return 1 }
    # The user and root slots go at the top of the Flags section.
    perl -0777 -pi -e 's/^(## Flags[ \t]*\n)\n*/$1\n- **User flag:** \n- **Root flag:** \n\n/m' $1
  fi
  K=$2 FLAG=$3 perl -0777 -pi -e '
    s/(^\*\*$ENV{K} flag\*\*[ \t]*\n> \[!success\][^\n]*\n)>[ \t]*\n/$1> $ENV{FLAG}\n/m
      or s/^(- \*\*$ENV{K} flag:\*\*)[ \t]*$/$1 $ENV{FLAG}/m;
  ' $1
}

# Host flags of note $1: reply=("host flag" ...), in order.
_dz_flags_list() {
  local out=$(perl -0777 -ne '
    if (/^## Flags[ \t]*\n(.*?)(?=^## |\z)/sm) {
      my $sec = $1;
      print "$1 $2\n" while $sec =~ /^- \d{4}-\d\d-\d\d \d\d:\d\d · (\S+) · (\S+)[ \t]*$/mg;
    }' $1)
  reply=(${(f)out})
}

# _dz_flags_add <note> <host> <flag>: a line at the end of the Flags section (added when
# the note has none).
_dz_flags_add() {
  local ts; strftime -s ts '%F %H:%M' $EPOCHSECONDS
  _dz_section_ensure $1 Flags || { _dz_err E413 "the note has no '## Flags' section (add_sections = no)"; return 1 }
  ENTRY="- $ts · $2 · $3" perl -0777 -pi -e '
    s{(^## Flags[ \t]*\n)(.*?)(?=^## |\z)}{
      my ($head, $body) = ($1, $2);
      $body =~ s/\s+\z//;
      # Straight under an earlier flag line, otherwise after a blank line (a list right
      # under a callout would end up inside it).
      my $sep = $body eq "" ? "\n" : $body =~ /^- \d{4}-[^\n]*\z/m ? "$body\n" : "$body\n\n";
      $head . $sep . "$ENV{ENTRY}\n\n"
    }sme;
  ' $1
}

# dz -f [user|root|<host>] [flag]
_dz_flag() {
  emulate -L zsh
  local kind=$1 flag=$2 note l
  _dz_note_need || return 1; note=$REPLY
  _dz_box_read $DZ_ROOT/$BOX 2>/dev/null
  local -a extra=("${_dz_bh[@]}")
  _dz_flags_get $note
  local user=$reply[1] root=$reply[2]
  _dz_flags_list $note
  local -a list=("${reply[@]}")
  local -i have=$(( $#list + ($#user > 0) + ($#root > 0) ))

  if [[ -z $flag ]]; then                                # show
    (( $#list && ! $#user && ! $#root )) || printf '%-5s %s\n' user "${user:--}" root "${root:--}"
    for l in $list; do printf '%-12s %s\n' ${l%% *} ${l#* }; done
    if (( DZ_FLAG_GOAL )); then print "  $have/$DZ_FLAG_GOAL flags"
    elif (( $#list )); then print "  $have flags"
    fi
    return 0
  fi
  [[ $flag == *[[:space:]]* ]] && { _dz_err E403 "a flag has no spaces"; return 1 }
  [[ -z $kind && ( $flag == $BOX || -n ${(M)extra:#${(b)flag} *} ) ]] &&
    { _dz_err E404 "$flag is a host, give the flag too: dz -f $flag <flag>"; return 1 }
  [[ $flag == "$user" || $flag == "$root" || -n ${(M)list:#* ${(b)flag}} ]] &&
    { _dz_err E405 "that flag is already in the note"; return 1 }
  # A box with more hosts, or a note without user/root slots (the exam template): flags
  # per host, the active one when you don't name it.
  [[ -z $kind ]] && { (( $#extra )) || ! grep -qE '^(- )?\*\*User flag' $note } && kind=${DZ_ACTIVE:-$BOX}
  if [[ -n $kind && $kind != (user|root) ]]; then
    [[ $kind == $BOX || -n ${(M)extra:#$kind *} ]] ||
      { _dz_err E407 "no host '$kind' in $BOX (dz -t lists them), or use user / root"; return 1 }
    [[ $flag =~ '^[0-9a-f]{32}$' ]] || _dz_warn W401 "'$flag' is not the usual HTB flag (32 hex), stored anyway"
    _dz_flags_add $note $kind $flag || return 1
    _dz_flags_list $note
    [[ -n ${(M)reply:#$kind ${(b)flag}} ]] || { _dz_err E408 "couldn't place the flag in $note"; return 1 }
    (( have++ ))
    local count=$have
    (( DZ_FLAG_GOAL )) && count=$have/$DZ_FLAG_GOAL
    _dz_timeline_add $note "flag $count ($kind)"
    print "• flag $count stored for $kind"
    (( DZ_FLAG_GOAL && have == DZ_FLAG_GOAL )) && print "• that's all $DZ_FLAG_GOAL, dz -d marks $BOX done"
    return 0
  fi
  if [[ -z $kind ]]; then
    if [[ -z $user ]]; then kind=user
    elif [[ -z $root ]]; then kind=root
    else _dz_err E406 "$BOX already has both flags, see dz -f"; return 1
    fi
  fi
  local -i idx; [[ $kind == user ]] && idx=1 || idx=2
  local cur; (( idx == 1 )) && cur=$user || cur=$root
  [[ -n $cur ]] && { _dz_err E406 "$BOX already has a $kind flag ($cur). Change it in the note."; return 1 }
  [[ $flag =~ '^[0-9a-f]{32}$' ]] || _dz_warn W401 "'$flag' is not the usual HTB flag (32 hex), stored anyway"

  _dz_flags_set $note ${(C)kind} $flag || return 1
  _dz_flags_get $note
  [[ $reply[idx] == $flag ]] ||
    { _dz_err E408 "couldn't place the flag in $note (Flags section changed?)"; return 1 }
  _dz_timeline_add $note "$kind flag"
  print "• $kind flag stored in the note"
  # One root flag finishes a single box, not a set of hosts.
  if [[ $kind == root ]] && (( ! $#extra )); then
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

# Is screenshot tool $1 installed? grim needs slurp to select the region.
_dz_shot_has() {
  [[ $1 == grim ]] && { (( $+commands[grim] && $+commands[slurp] )); return }
  (( $+commands[$1] ))
}

# Screenshot tool: 'screenshot' from the config, or the first one found. On Wayland
# (sway, Hyprland, KDE, GNOME) the Wayland tools first: the X11 ones see nothing there.
_dz_shot_tool() {
  local t
  if [[ $DZ_SHOT != auto ]]; then
    _dz_shot_has $DZ_SHOT && { REPLY=$DZ_SHOT; return 0 }
    _dz_err E409 "screenshot tool '$DZ_SHOT' not found${${(M)DZ_SHOT:#grim}:+ (grim needs slurp too)}"; return 1
  fi
  local -a tools=(xfce4-screenshooter flameshot gnome-screenshot spectacle import)
  [[ -n $WAYLAND_DISPLAY ]] && tools=(grim spectacle gnome-screenshot flameshot)
  for t in $tools; do
    _dz_shot_has $t && { REPLY=$t; return 0 }
  done
  _dz_err E409 "no screenshot tool found (${(j:, :)${(@)tools/#%grim/grim + slurp}})"
  return 1
}

# _dz_shot_take <tool> <file>: select a region and save it as PNG.
_dz_shot_take() {
  local g
  case $1 in
    xfce4-screenshooter) xfce4-screenshooter -r -s $2 ;;
    flameshot)           flameshot gui -r > $2 ;;
    gnome-screenshot)    gnome-screenshot -a -f $2 ;;
    spectacle)           spectacle -r -b -n -o $2 ;;
    grim)                g=$(slurp) && grim -g "$g" $2 ;;   # Esc in slurp = no screenshot
    import)              import $2 ;;
  esac 2>/dev/null
}

# dz -s [caption]: screenshot to evidence/, a copy in the vault, embedded in the timeline
# (or under the active finding, see findings.zsh).
_dz_shot() {
  emulate -L zsh -o extended_glob
  local caption=${1//$'\n'/ } note='' tool
  if [[ $DZ_NOTE_MODE == off ]]; then
    [[ -n $BOX ]] || { _dz_err E201 "no box loaded"; return 1 }
  else
    _dz_note_need || return 1; note=$REPLY
  fi
  [[ -n $DISPLAY || -n $WAYLAND_DISPLAY ]] || { _dz_err E410 "no desktop session for a screenshot"; return 1 }
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
  _dz_evidence_place $note "screenshot${caption:+: $caption}" "  $embed"
  print "• screenshot: ${ev/#$HOME/~}/$name (${REPLY:+under $REPLY }in the note too)"
  _dz_reptor file $ev/$name
}

# dz -g <term> [--all]: every line with <term> (any case) in the notes of all boxes, per
# box with its line number. 'Where did I see that before?' across boxes.
_dz_grep() {
  emulate -L zsh -o extended_glob
  local term=$1 all=$2 b note l text
  [[ -n $term ]] || { _dz_err E102 "-g needs a search term (dz -g <term>)"; return 1 }
  [[ $DZ_NOTE_MODE == off ]] && { _dz_err E401 "notes are off (notes = off in the config)"; return 1 }
  local -a boxes=($DZ_ROOT/*/.dropzone(Nn:h:t)) hits
  [[ -n $all ]] && boxes+=($DZ_ROOT/_archive/*/.dropzone(Nn:h:t))
  _dz_ui
  local on=$_ug off=$_ur
  local -i n=0 nb=0
  for b in $boxes; do
    note=$(_dz_note $b) && [[ -f $note ]] || continue
    hits=(${(f)"$(grep -n -i -F -- "$term" $note 2>/dev/null)"})
    (( $#hits )) || continue
    (( nb++, n += $#hits ))
    _dz_head $b "$#hits"
    for l in $hits; do
      text=${${l#*:}##[[:space:]]#}
      [[ -n $on ]] && text=${text//(#bi)(${(b)term})/$on$match[1]$off}
      printf '    %s%5s%s  %s
' "$_ud" ${l%%:*} "$_ur" "$text"
    done
  done
  local nt=$#boxes
  if (( n )); then print "• $n line${${n:#1}:+s} in $nb of $nt box${${nt:#1}:+es}"
  else
    print "• no '$term' in the notes of $nt box${${nt:#1}:+es}"
    [[ -n $all ]] || print "  dz -g ${(q-)term} --all also searches the archive"
  fi
}

# The command that is piping into dz -e, from commands.log (logged just before it ran),
# without the '| dz -e ...' part. Empty when logging is off or the line doesn't match.
_dz_evidence_cmd() {
  emulate -L zsh -o extended_glob
  REPLY=''
  local log=$DZ_ROOT/$BOX/logs/commands.log line
  [[ -s $log ]] || return 0
  line=$(tail -n 1 $log)
  line=${line#*  \$ }
  [[ $line == *\|[[:space:]]#dz[[:space:]]##(-e|--evidence)* ]] || return 0
  REPLY=${line%%[[:space:]]#\|[[:space:]]#dz[[:space:]]##(-e|--evidence)*}
}

# <cmd> | dz -e [caption]: the output (colours stripped) to evidence/<box>_<date>_<time>_<caption>.txt
# with the command on top, and the first lines as a code block in the timeline.
_dz_evidence() {
  emulate -L zsh -o extended_glob
  local caption=${1//$'\n'/ } note='' out cmd fnd=''
  if [[ $DZ_NOTE_MODE == off ]]; then
    [[ -n $BOX ]] || { _dz_err E201 "no box loaded"; return 1 }
  else
    _dz_note_need || return 1; note=$REPLY
  fi
  [[ -t 0 ]] && { _dz_err E411 "pipe a command into it: nxc smb \$TARGET | dz -e smb signing"; return 1 }
  out=$(perl -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g; s/\e\][^\a]*\a//g; s/\r//g')
  [[ -n ${out//[[:space:]]/} ]] || { _dz_err E412 "no output to save"; return 1 }
  _dz_evidence_cmd; cmd=$REPLY

  local ts slug name ev=$DZ_ROOT/$BOX/evidence
  strftime -s ts '%F_%H%M%S' $EPOCHSECONDS
  slug=${${${(L)caption}//[^a-z0-9]##/-}##-}; slug=${${slug[1,40]}%%-}
  name=${BOX}_$ts${slug:+_$slug}.txt
  mkdir -p $ev || return 1
  { [[ -n $cmd ]] && print -r -- "\$ $cmd"$'\n'; print -r -- $out } > $ev/$name

  local -a lines=("${(@f)out}")
  local -i max=30
  local block="\`\`\`\`text"
  [[ -n $cmd ]] && block+=$'\n'"\$ $cmd"
  block+=$'\n'"${(pj:\n:)lines[1,max]}"
  (( $#lines > max )) && block+=$'\n'"... $(( $#lines - max )) more lines in evidence/$name"
  block+=$'\n'"\`\`\`\`"
  if [[ -n $note ]]; then
    local -a bl=("${(@f)block}"); bl=("  "${^bl})
    _dz_evidence_place $note "output${caption:+: $caption} (evidence/$name)" "${(F)bl}"; fnd=$REPLY
    print "• output: ${ev/#$HOME/~}/$name ($#lines lines, ${fnd:+under $fnd }in the note too)"
  else
    print "• output: ${ev/#$HOME/~}/$name ($#lines lines)"
  fi
  _dz_reptor note "**${fnd:+$fnd · }${caption:-output}**"$'\n\n'"\`\`\`"$'\n'"${cmd:+\$ $cmd}"$'\n'"$out"$'\n'"\`\`\`"
  return 0
}
