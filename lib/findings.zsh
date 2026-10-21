# findings: findings with their evidence, in the note's '## Findings' section.
#
#   dz --finding <title>       new finding F<n> on the active host, and make it the active one
#   dz --finding               list them (▶ = active)
#   dz --finding <nr>          make F<nr> active (2 or F2)
#   dz --finding off           no active finding: evidence goes to the timeline again
#   dz --finding done [nr]     mark it done (the active one without a number)
#
# Every finding is a '### F<n> · <title>' heading under '## Findings', with a line
# '**Host:** <host> · **Status:** open' under it. While a finding is active, dz -s and dz -e
# put their evidence under its heading and the timeline gets a short line that points to it.
# A table under '## Findings' (the exam template) gets a row per finding; its columns are
# found by name (#, Finding, Host, Evidence, Status) and kept up to date.
# The active finding is ~/boxes/<box>/.finding (just its number), read, never sourced.

# Findings in note $1: reply=("<nr>\t<host>\t<status>\t<evidence count>\t<title>" ...).
_dz_findings() {
  local out=$(perl -0777 -ne '
    if (/^## Findings[ \t]*\n(.*?)(?=^## |\z)/sm) {
      my $sec = $1;
      while ($sec =~ /^### F(\d+) · ([^\n]*?)[ \t]*\n(.*?)(?=^\#{1,3} |\z)/smg) {
        my ($n, $t, $b) = ($1, $2, $3);
        my ($h) = $b =~ /\*\*Host:\*\*[ \t]*([^\s·]+)/;
        my ($s) = $b =~ /\*\*Status:\*\*[ \t]*(\w+)/;
        my $c = () = $b =~ /^- \d{4}-\d\d-\d\d \d\d:\d\d · /mg;
        print join("\t", $n, $h // "", $s // "open", $c, $t), "\n";
      }
    }' $1)
  reply=(${(f)out})
}

# The active finding of the loaded box in $REPLY (its number); reply holds every finding
# (_dz_findings). Fails when there is none, or when its heading is gone from note $1: then
# the .finding file goes too, with a warning. $2 = peek: only look, change nothing.
_dz_finding_active() {
  local f=$DZ_ROOT/$BOX/.finding n
  REPLY=''
  [[ -f $f ]] || return 1
  n=$(<$f)
  [[ $n == <1-> ]] || { [[ -n $2 ]] || rm -f $f; return 1 }
  _dz_findings $1
  if [[ -z ${(M)reply:#$n$'\t'*} ]]; then
    [[ -n $2 ]] && return 1
    rm -f $f
    _dz_warn W404 "F$n isn't in the note anymore, evidence goes to the timeline"
    return 1
  fi
  REPLY=$n
}

# _dz_finding_new <note> <nr> <title> <host>: a row in the Findings table (when there is
# one before the first finding) and the '### F<nr> · <title>' heading at the end.
_dz_finding_new() {
  N=$2 TITLE=$3 HOST=$4 perl -0777 -pi -e '
    s{(^## Findings[ \t]*\n)(.*?)(?=^## |\z)}{
      my ($head, $body) = ($1, $2);
      my ($pre, $rest) = $body =~ /\A(.*?)(^### .*)?\z/sm;
      $rest //= "";
      (my $t = $ENV{TITLE}) =~ s/\|/\\|/g;
      $pre =~ s{(\|[^\n]*\|)[ \t]*\n(\|[ :-]*-[ |:-]*\|?[ \t]*\n)((?:\|[^\n]*\n)*)}{
        my ($th, $sep, $rows) = ($1, $2, $3);
        my @c = map { s/^\s+|\s+$//gr } grep { length } split /(?<!\\)\|/, $th;
        if (grep { /^(finding|title|issue)$/i } @c) {
          my @v = map {
            /^(#|nr|no|id)$/i ? "F$ENV{N}" : /^(finding|title|issue)$/i ? $t : /^host/i ? $ENV{HOST}
              : /^status/i ? "open" : /^evidence/i ? "0" : ""
          } @c;
          $rows =~ s/^\|(?:\s*\|)+\s*\n//mg;
          "$th\n$sep$rows|" . join("|", map { length ? " $_ " : " " } @v) . "|\n"
        } else { "$th\n$sep$rows" }
      }e;
      $body = $pre . $rest;
      $body =~ s/\A\s+//; $body =~ s/\s+\z//;
      $head . "\n" . ($body eq "" ? "" : "$body\n\n")
        . "### F$ENV{N} · $ENV{TITLE}\n\n**Host:** $ENV{HOST} · **Status:** open\n\n"
    }sme;
  ' $1
}

# _dz_finding_row <note> <nr> <status|evidence> <value>: that cell in the Findings table
# row of F<nr>. Value '+1' adds one to a number. Without a table or column: nothing.
_dz_finding_row() {
  N=$2 COL=$3 VAL=$4 perl -0777 -pi -e '
    s{(^## Findings[ \t]*\n(?:(?!\#{1,3} ).*\n)*?)(\|[^\n]*)\n(\|[ :-]*-[ |:-]*\|?[ \t]*\n)((?:\|[^\n]*\n)*)}{
      my ($pre, $th, $sep, $rows) = ($1, $2, $3, $4);
      my @h = map { s/^\s+|\s+$//gr } split /(?<!\\)\|/, $th;
      my ($in) = grep { $h[$_] =~ /^(#|nr|no|id)$/i } 0..$#h;
      my ($ic) = grep { $h[$_] =~ /^\Q$ENV{COL}\E/i } 0..$#h;
      if (defined $in && defined $ic) {
        $rows = join "", map {
          my @c = split /(?<!\\)\|/, $_, -1;
          if ((($c[$in] // "") =~ s/^\s+|\s+$//gr) eq "F$ENV{N}") {
            my $old = ($c[$ic] // "") =~ s/^\s+|\s+$//gr;
            my $new = $ENV{VAL} eq "+1" ? ($old =~ /^\d+$/ ? $old + 1 : 1) : $ENV{VAL};
            $c[$ic] = " $new ";
            join("|", @c)
          } else { $_ }
        } split /^/m, $rows;
      }
      "$pre$th\n$sep$rows"
    }me' $1
}

# _dz_finding_add <note> <nr> <entry>: '- <date> <time> · <entry>' at the end of F<nr>.
# Extra lines in <entry> (an embed, a code block) stay under it.
_dz_finding_add() {
  local ts; strftime -s ts '%F %H:%M' $EPOCHSECONDS
  N=$2 ENTRY="- $ts · $3" TODAY=${ts% *} perl -0777 -pi -e '
    s{(^### F$ENV{N} · [^\n]*\n)(.*?)(?=^\#{1,3} |\z)}{
      my ($head, $body) = ($1, $2);
      $body =~ s/\A\s+//; $body =~ s/\s+\z//;
      # Right under an earlier entry, otherwise after a blank line (the Host line).
      my $sep = $body eq "" ? "" : $body =~ /^- \d{4}-\d\d-\d\d /m ? "$body\n" : "$body\n\n";
      $head . "\n" . $sep . "$ENV{ENTRY}\n\n"
    }sme;
    s/^updated: .*$/updated: $ENV{TODAY}/m;
  ' $1
  _dz_finding_row $1 $2 evidence +1
}

# _dz_finding_status <note> <nr> <status>: the Status on the line under the heading, and
# in the table.
_dz_finding_status() {
  N=$2 S=$3 perl -0777 -pi -e '
    s{(^### F$ENV{N} · [^\n]*\n(?:(?!\#{1,3} ).*\n)*?[^\n]*\*\*Status:\*\*[ \t]*)\w+}{$1$ENV{S}}m
  ' $1
  _dz_finding_row $1 $2 status $3
}

# _dz_evidence_place <note> <label> <body>: under the active finding, with a short line in
# the timeline, or straight into the timeline. $REPLY = 'F<n>' when it went to a finding.
_dz_evidence_place() {
  local n
  if _dz_finding_active $1; then
    n=$REPLY
    _dz_finding_add $1 $n "$2"$'\n'"$3"
    _dz_timeline_add $1 "$2 → F$n"
    REPLY=F$n
    return 0
  fi
  REPLY=''
  _dz_timeline_add $1 "$2"$'\n'"$3"
  (( ! _dz_tl_skip ))
}

# dz --finding [title | <nr> | off | done [nr]]
_dz_finding() {
  emulate -L zsh -o extended_glob
  local text=${${${1//$'\n'/ }##[[:space:]]#}%%[[:space:]]#} note l n f=$DZ_ROOT/$BOX/.finding
  local -a w
  _dz_note_need || return 1; note=$REPLY
  local cur=''
  if _dz_finding_active $note; then cur=$REPLY; else _dz_findings $note; fi
  local -a all=("${reply[@]}")

  # List
  if [[ -z $text ]]; then
    (( $#all )) || { print -r -- "no findings in $BOX yet"; print "  dz --finding <title> starts one"; return 0 }
    for l in $all; do
      w=("${(@ps:\t:)l}")
      printf '%s %-4s %-12s %-5s %2d evidence  %s\n' "${${${w[1]:#$cur}:+ }:-▶}" F$w[1] "${w[2]:--}" $w[3] $w[4] "$w[5]"
    done
    [[ -n $cur ]] && print "  dz -s and dz -e go under F$cur · dz --finding off stops that" ||
      print "  no active finding · dz --finding <nr> picks one"
    return 0
  fi

  local lc=${(L)text}
  # Stop
  if [[ $lc == off ]]; then
    rm -f $f
    print -r -- "• no active finding${cur:+ (was F$cur)}, evidence goes to the timeline"
    return 0
  fi

  # Done, or make one active: 'done [nr]', '<nr>', 'F<nr>'.
  if [[ $lc == (done([[:space:]]##(f|)<1->|)|(f|)<1->) ]]; then
    local mode=pick
    [[ $lc == done* ]] && { mode=done; lc=${lc#done} }
    n=${${lc//[[:space:]]/}#f}
    [[ -z $n ]] && { n=$cur; [[ -n $n ]] || { _dz_err E417 "no active finding, give its number: dz --finding done <nr>"; return 1 } }
    local hit=${(M)all:#$n$'\t'*}
    [[ -n $hit ]] || { _dz_err E417 "no finding F$n in $BOX (dz --finding lists them)"; return 1 }
    w=("${(@ps:\t:)hit}")
    if [[ $mode == pick ]]; then
      print $n > $f
      if [[ $w[3] == done ]]; then
        _dz_finding_status $note $n open
        _dz_timeline_add $note "finding F$n open again: $w[5]"
        print -r -- "• active: F$n · $w[5] (was done, open again)"
      else
        print -r -- "• active: F$n · $w[5] (dz -s and dz -e go under it)"
      fi
      return 0
    fi
    [[ $w[3] == done ]] && { print -r -- "• F$n is already done"; return 0 }
    _dz_finding_status $note $n done
    [[ $n == $cur ]] && rm -f $f
    _dz_timeline_add $note "finding F$n done: $w[5]"
    if [[ $n == $cur ]]; then print -r -- "• F$n done: $w[5] (no active finding now)"
    else print -r -- "• F$n done: $w[5]"
    fi
    return 0
  fi

  # New
  _dz_section_ensure $note Findings "$DZ_TIMELINE" Flags ||
    { _dz_err E413 "the note has no '## Findings' section (add_sections = no)"; return 1 }
  local host=${DZ_ACTIVE:-$BOX}
  # The next number: after the highest in a heading or a table row, so a finding removed
  # by hand never gets its number reused.
  n=$(perl -0777 -ne '
    my $m = 0;
    if (/^## Findings[ \t]*\n(.*?)(?=^## |\z)/sm) {
      my $s = $1;
      for ($s =~ /^(?:### |\|[ \t]*)F(\d+)\b/mg) { $m = $_ if $_ > $m }
    }
    print $m + 1' $note)
  _dz_finding_new $note $n "$text" $host
  _dz_findings $note
  [[ -n ${(M)reply:#$n$'\t'*} ]] || { _dz_err E418 "couldn't add the finding to $note"; return 1 }
  print $n > $f
  _dz_timeline_add $note "finding F$n: $text ($host)"
  print -r -- "• F$n · $text ($host)"
  print "  dz -s and dz -e go under it now · dz --finding off stops that"
}
