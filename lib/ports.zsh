# ports: open ports from your own nmap output into the note (dz -p). It never scans.
#
#   dz -p                  the newest .xml or .gnmap in scans/
#   dz -p scans/all.xml    a given file (nmap -oX, or -oA for both)
#
# Every open port becomes a row in the first table under '## Ports' (or '### Poorten');
# rows that are already there, with your own notes, stay as they are. IPs are matched
# to the box's hosts (dz -t), so one scan of a whole AD set lands under the right host.

# _dz_nmap_parse <file>: "ip<TAB>port<TAB>proto<TAB>service<TAB>version" per open port.
_dz_nmap_parse() {
  perl -0777 -ne '
    sub clean { my $s = shift // ""; $s =~ s/&amp;/&/g; $s =~ s/&lt;/</g; $s =~ s/&gt;/>/g;
                $s =~ s/&quot;/"/g; $s =~ s/&#x?[0-9a-f]+;//gi; $s =~ s/[|\t\n]/ /g; $s =~ s/^\s+|\s+$//gr }
    if (/<nmaprun/) {
      while (/<host\b.*?<\/host>/gs) {
        my $h = $&;
        my ($ip) = $h =~ /<address addr="([\d.]+)" addrtype="ipv4"/ or next;
        while ($h =~ /<port protocol="(\w+)" portid="(\d+)">(.*?)<\/port>/gs) {
          my ($proto, $port, $b) = ($1, $2, $3);
          next unless $b =~ /<state state="open"/;
          my ($svc) = $b =~ /<service [^>]*\bname="([^"]*)"/;
          my @v = map { my ($x) = $b =~ /<service [^>]*\b$_="([^"]*)"/; $x } qw(product version extrainfo);
          $v[2] = "($v[2])" if defined $v[2];
          print join("\t", $ip, $port, $proto, clean($svc), clean(join " ", grep { defined } @v)), "\n";
        }
      }
    } else {
      for (split /\n/) {
        next unless /^Host: ([\d.]+) .*?\tPorts: ([^\t]*)/;
        my $ip = $1;
        for (split /, /, $2) {
          my ($port, $state, $proto, undef, $svc, undef, $ver) = split m{/};
          next unless ($state // "") eq "open";
          print join("\t", $ip, $port, $proto, clean($svc), clean($ver)), "\n";
        }
      }
    }' $1
}

# _dz_ports_note <note> <rows>: rows "host<TAB>port<TAB>proto<TAB>service<TAB>version".
# Prints how many rows were added.
_dz_ports_note() {
  ROWS=$2 HOSTS=$3 perl -0777 -pi -e '
    my %known = map { lc($_) => 1 } split / /, $ENV{HOSTS};
    my @new = map { [split /\t/, $_, -1] } grep { length } split /\n/, $ENV{ROWS};
    my $added = 0;
    s{(^\#{2,3} (?:Ports|Poorten)[^\n]*\n(?:(?!\#{1,3} ).*\n)*?)(\|[^\n]*\|)[ \t]*\n(\|[ :-]*-[ |:-]*\|?[ \t]*\n)((?:\|[^\n]*\n)*)}{
      my ($pre, $head, $sep, $rows) = ($1, $2, $3, $4);
      my @c = map { s/^\s+|\s+$//gr } grep { length } split /\|/, $head;
      my %col;
      for my $i (0 .. $#c) {
        my $n = $c[$i];
        $col{port}  //= $i if $n =~ /^(port|poort)s?$/i;
        $col{proto} //= $i if $n =~ /^proto/i;
        $col{state} //= $i if $n =~ /^(state|status)$/i;
        $col{svc}   //= $i if $n =~ /^service/i;
        $col{ver}   //= $i if $n =~ /^(version|versie)/i;
        $col{host}  //= $i if $n =~ /^(host|machine)$/i;
        $col{note}  //= $i if $n =~ /^(notes?|opmerking|notities|remarks?)$/i;
      }
      if (defined $col{port}) {
        my (%have, @keep);
        for my $r (split /\n/, $rows) {
          my @v = map { s/^\s+|\s+$//gr } split /\|/, $r; shift @v;
          next if ($v[$col{port}] // "") eq "";              # empty example row
          # Port and protocol: "22/tcp" in one cell, or a Proto column of its own.
          my ($pt, $pr) = ($v[$col{port}] // "") =~ m{^(\d+)(?:/(\w+))?};
          $pr = $v[$col{proto}] if defined $col{proto} && length($v[$col{proto}] // "");
          # Host: its own column, or the first word of the notes column when that is a
          # known host. Unknown = matches any host, so an edited row never gets a twin.
          my $h = "";
          if (defined $col{host}) { $h = lc($v[$col{host}] // "") }
          elsif (defined $col{note} && ($v[$col{note}] // "") =~ /^(\S+)/ && $known{lc $1}) { $h = lc $1 }
          $have{"$h/" . ($pt // "") . "/" . lc($pr // "")} = 1;
          push @keep, "$r\n";
        }
        my @add;
        for my $n (sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] } @new) {
          my ($host, $port, $proto, $svc, $ver, $label) = @$n;
          my $h = lc $host; my $p = lc $proto;
          next if $have{"$h/$port/$p"} || $have{"/$port/$p"};
          $have{"$h/$port/$p"} = 1;
          # Without a proto column the port reads 22/tcp; without a host column the
          # host goes into the notes column when the box has more hosts.
          my @v = ("") x @c;
          $v[$col{port}]  = defined $col{proto} ? $port : "$port/$proto";
          $v[$col{proto}] = uc $proto if defined $col{proto};
          $v[$col{state}] = "open" if defined $col{state};
          $v[$col{svc}]   = $svc if defined $col{svc};
          $v[$col{ver}]   = $ver if defined $col{ver};
          if (defined $col{host}) { $v[$col{host}] = $host }
          elsif (defined $col{note} && $label) { $v[$col{note}] = $host }
          push @add, "|" . join("|", map { length ? " $_ " : " " } @v) . "|\n";
          $added++;
        }
        $rows = join "", @keep, @add;
      }
      "$pre$head\n$sep$rows"
    }me;
    END { print STDERR $added + 0 }
  ' $1 2>&1 >/dev/null | tail -1
}

# dz -p [file]
_dz_ports() {
  emulate -L zsh -o extended_glob
  local file=$1 note='' l
  [[ -n $BOX ]] || { print -u2 "dz: no box loaded"; return 1 }
  _dz_box_read $DZ_ROOT/$BOX || { print -u2 "dz: box '$BOX' is gone (removed or archived?)"; return 1 }
  local main_ip=$reply[2]
  if [[ -z $file ]]; then
    local -a found=($DZ_ROOT/$BOX/scans/**/*.(xml|gnmap)(N.om[1]))
    (( $#found )) || { print -u2 "dz: no .xml or .gnmap in $DZ_ROOT/$BOX/scans/ (nmap -oA scans/<name> ...)"; return 1 }
    file=$found[1]
  fi
  [[ -r $file ]] || { print -u2 "dz: can't read $file"; return 1 }

  # IP -> host name: the main host is the box name, the rest come from dz -t.
  local -A name=($main_ip $BOX)
  local -a w
  for l in $_dz_bh; do w=(${=l}); name[$w[2]]=$w[1]; done
  local multi=$(( $#_dz_bh > 0 ))

  local -a rows=() other=() shown=()
  local ip port proto svc ver
  while IFS=$'\t' read -r ip port proto svc ver; do
    [[ -n $ip ]] || continue
    if (( ! $+name[$ip] )); then
      (( ${other[(I)$ip]} )) || other+=($ip)
      continue
    fi
    rows+=("$name[$ip]"$'\t'"$port"$'\t'"$proto"$'\t'"$svc"$'\t'"$ver"$'\t'"$multi")
    shown+=("$(printf '  %-12s %-10s %-14s %s' $name[$ip] $port/$proto "$svc" "$ver")")
  done < <(_dz_nmap_parse $file)

  (( $#other )) && print -u2 "• not in $BOX, skipped: $other (add a host with dz -t <host> -ip <ip>)"
  (( $#rows )) || { print "• no open ports for $BOX in ${file/#$HOME/~}"; return 0 }
  print -rl -- $shown

  note=$(_dz_note $BOX 2>/dev/null) && [[ -f $note ]] || {
    print "• ${#rows} open ports (no note to write them to)"; return 0 }
  local n=$(_dz_ports_note $note "${(F)rows}" "${(j: :)${(k)name}} ${(j: :)${(v)name}}")
  local hostlist=(${(u)${rows%%$'\t'*}})
  if (( n )); then
    _dz_timeline_add $note "nmap: $n open ports on ${(j:, :)hostlist} (${file:t})"
    print "• $n new ports in the note, ${#rows} open in total"
  else
    print "• the note already has all ${#rows} open ports"
  fi
  grep -qE '^#{2,3} (Ports|Poorten)' $note || print -u2 "• the note has no '## Ports' table, see docs/notes.md"
  return 0
}
