# todo: your own to-do list per box, in the note's '## To do' section.
#
#   dz --todo <text>         '- [ ] <text>', tagged with the active host in a box with more hosts
#   dz --todo                the open ones, numbered
#   dz --todo --all          the done ones too
#   dz --todo done <nr>      tick one off (ticking it in Obsidian works too)
#
# The note is the list: dz reads it every time, so editing it by hand is fine. A number is
# the item's place in the section, so it stays the same when you tick items off.
# dz never writes to-dos itself: what to try next is your call.

typeset -g _dz_todo_head='To do'

# Items in note $1: reply=("<nr>\t<x or space>\t<host>\t<text>" ...). <host> is set when the
# item starts with '<host> · ' and that host is in $2 (space separated).
_dz_todo_items() {
  local out=$(HEAD=$_dz_todo_head HOSTS=" $2 " perl -0777 -ne '
    if (/^## \Q$ENV{HEAD}\E[ \t]*\n(.*?)(?=^## |\z)/sm) {
      my $n = 0;
      for (split /\n/, $1) {
        next unless /^- \[([ xX])\][ \t]+(\S.*?)\s*$/;
        my ($s, $t, $h) = (lc $1, $2, "");
        $n++;
        ($h, $t) = ($1, $2) if $t =~ /^(\S+) · (.+)$/ && index($ENV{HOSTS}, " $1 ") >= 0;
        print join("\t", $n, $s, $h, $t), "\n";
      }
    }' $1)
  reply=(${(f)out})
}

# _dz_todo_add <note> <line>: the line at the end of the To do section. An empty template
# bullet ('- [ ]' or '-') goes.
_dz_todo_add() {
  HEAD=$_dz_todo_head ENTRY=$2 perl -0777 -pi -e '
    s{(^## \Q$ENV{HEAD}\E[ \t]*\n)(.*?)(?=^## |\z)}{
      my ($head, $body) = ($1, $2);
      $body =~ s/^-(?:[ \t]+\[[ xX]?\])?[ \t]*\n//mg;
      $body =~ s/\A\s+//; $body =~ s/\s+\z//;
      $head . "\n" . ($body eq "" ? "" : "$body\n") . "$ENV{ENTRY}\n\n"
    }sme;
  ' $1
}

# _dz_todo_tick <note> <nr>: '- [ ]' of item <nr> becomes '- [x]'.
_dz_todo_tick() {
  HEAD=$_dz_todo_head N=$2 perl -0777 -pi -e '
    s{(^## \Q$ENV{HEAD}\E[ \t]*\n)(.*?)(?=^## |\z)}{
      my ($head, $body) = ($1, $2);
      my $n = 0;
      $body =~ s{^- \[([ xX])\](?=[ \t]+\S)}{ ++$n == $ENV{N} ? "- [x]" : "- [$1]" }mge;
      $head . $body
    }sme;
  ' $1
}

# dz --todo [text | --all | done <nr>]. $2 = new: the text is always a to-do (the menu form).
_dz_todo() {
  emulate -L zsh -o extended_glob
  local text=${${${1//$'\n'/ }##[[:space:]]#}%%[[:space:]]#} new=$2 note l
  local -a w
  _dz_note_need || return 1; note=$REPLY
  _dz_box_read $DZ_ROOT/$BOX 2>/dev/null
  local -a hosts=($BOX ${_dz_bh%% *})
  local -i extra=$#_dz_bh

  # List
  [[ -n $new && -z $text ]] && { print "• no text, no to-do"; return 1 }
  if [[ -z $new ]] && [[ -z $text || ${(L)text} == --all ]]; then
    _dz_todo_items $note "$hosts"
    local -i open=0 done=0 hw=0
    for l in $reply; do
      w=("${(@ps:\t:)l}")
      if [[ $w[2] == x ]]; then (( done++ )); else (( open++ )); fi
      (( $#w[3] > hw )) && hw=$#w[3]
    done
    if (( ! open )) && [[ -z $text || done -eq 0 ]]; then
      print -r -- "no open to-dos for $BOX$( (( done )) && print " ($done done, dz --todo --all)")"
      print "  dz --todo <text> adds one"
      return 0
    fi
    local mark
    for l in $reply; do
      w=("${(@ps:\t:)l}")
      [[ $w[2] == x ]] && { [[ -n $text ]] || continue; mark=✓ } || mark=' '   # --all
      if (( hw )); then printf '%s %3d  %-*s  %s\n' $mark $w[1] $hw "$w[3]" "$w[4]"
      else printf '%s %3d  %s\n' $mark $w[1] "$w[4]"
      fi
    done
    print "  $open open$( (( done )) && print ", $done done") · dz --todo done <nr> ticks one off"
    return 0
  fi

  # Tick off: 'done <nr>'. Other text that starts with 'done' is a to-do.
  [[ -z $new && ${(L)text} == done ]] && { _dz_err E102 "--todo done needs the number of the to-do (dz --todo lists them)"; return 1 }
  if [[ -z $new && ${(L)text} =~ '^done[[:space:]]+([0-9]+)$' ]]; then
    local nr=$match[1] hit
    _dz_todo_items $note "$hosts"
    hit=${(M)reply:#$nr$'\t'*}
    [[ -n $hit ]] || { _dz_err E414 "no to-do #$nr in $BOX (dz --todo lists them)"; return 1 }
    w=("${(@ps:\t:)hit}")
    [[ $w[2] == x ]] && { _dz_err E415 "to-do #$nr is already done: $w[4]"; return 1 }
    _dz_todo_tick $note $nr
    _dz_todo_items $note "$hosts"
    [[ -n ${(M)reply:#$nr$'\t'x$'\t'*} ]] || { _dz_err E416 "couldn't tick off #$nr in $note"; return 1 }
    _dz_timeline_add $note "done: ${w[3]:+$w[3] · }$w[4]"
    print -r -- "• done: $w[4]"
    return 0
  fi

  # Add
  _dz_section_need $note $_dz_todo_head "$DZ_TIMELINE" Flags || return 1
  local host=''
  (( extra )) && host=${DZ_ACTIVE:-$BOX}
  _dz_todo_items $note "$hosts"; local -i before=$#reply
  _dz_todo_add $note "- [ ] ${host:+$host · }$text"
  _dz_todo_items $note "$hosts"
  (( $#reply > before )) || { _dz_err E416 "couldn't add the to-do to $note"; return 1 }
  print -r -- "• to-do #${${reply[-1]}%%$'\t'*}${host:+ ($host)}: $text"
}
