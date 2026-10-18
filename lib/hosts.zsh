# hosts: more than one host in a box (dz -t), for AD sets, pivots and labs.
#
#   dz -t dc01 -ip 10.10.10.5 [-h dc01.corp.local,corp.local]   add or change a host
#   dz -t                                                       list (▶ = active)
#   dz -t dc01                                                  make dc01 the target
#   dz -t <box>                                                 back to the main host
#   dz -t dc01 --drop                                           remove the host
#   dz -t ms01 -ip 172.16.5.10 --via web01                      ms01 sits behind pivot web01
#
# Every host gets $DC01_IP, all IPs are in $TARGETS, and $TARGET_IP / $TARGET / $DOMAIN
# follow the active host. The main host is the box itself (dz -n / dz -ip).

# Pivots live in ~/boxes/<box>/.via: a line '<host> <pivot>' per host behind a pivot.
# _dz_via_get <host>: its pivot in $REPLY, fails when it has none.
_dz_via_get() {
  local f=$DZ_ROOT/$BOX/.via l
  REPLY=''
  [[ -f $f ]] || return 1
  for l in "${(@f)$(<$f)}"; do
    [[ ${l%% *} == $1 ]] && _dz_valid_label ${l#* } && { REPLY=${l#* }; return 0 }
  done
  return 1
}

# _dz_via_set <host> [pivot]: set or clear the pivot of a host.
_dz_via_set() {
  local f=$DZ_ROOT/$BOX/.via
  local -a l=()
  [[ -f $f ]] && l=("${(@f)$(<$f)}")
  l=("${(@)l:#$1 *}")
  [[ -n $2 ]] && l+=("$1 $2")
  if (( $#l )); then print -rl -- $l > $f; else rm -f $f; fi
}

# The line of host $1 in _dz_bh (after _dz_box_read), in $REPLY. Fails when it's not there.
_dz_host_line() {
  local l
  for l in $_dz_bh; do [[ ${l%% *} == $1 ]] && { REPLY=$l; return 0 }; done
  return 1
}

# Write the box file with _dz_bh / _dz_ba changed, keep the main host as it is.
_dz_host_save() {
  _dz_box_write $DZ_ROOT/$BOX $BOX $1 "$2" "$_dz_ba" "${_dz_bh[@]}"
}

# Add a row for a new host to the first table under '## Hosts' (or '### Hosts') in the
# note. Fills the columns called Host (or Name), IP and Hostname(s) / FQDN; without a Host
# column the name goes into a Role / Notes column. An empty example row goes.
_dz_host_note() {
  local note
  note=$(_dz_note $BOX) && [[ -f $note ]] || return 0
  L=$1 IP=$2 HN=$3 VIA=$4 perl -0777 -pi -e '
    s{(^\#{2,3} Hosts[^\n]*\n(?:(?!\#{1,3} ).*\n)*?)(\|[^\n]*\|)[ \t]*\n(\|[ :-]*-[ |:-]*\|?[ \t]*\n)((?:\|[^\n]*\n)*)}{
      my ($pre, $head, $sep, $rows) = ($1, $2, $3, $4);
      my @c = map { s/^\s+|\s+$//gr } grep { length } split /\|/, $head;
      my @v = map {
        /^(hosts?|name|machine)$/i ? $ENV{L} : /^ip\b/i ? $ENV{IP} : /hostname|fqdn/i ? $ENV{HN} : /^(via|pivot)/i ? $ENV{VIA} : ""
      } @c;
      # No Host column: the name goes into a role / notes column, if there is one.
      unless (grep { /^(hosts?|name|machine)$/i } @c) {
        for my $i (0 .. $#c) { if ($c[$i] =~ /\b(role|rol|notes?|notities|opmerking)/i) { $v[$i] = $ENV{L}; last } }
      }
      $rows =~ s/^\|(?:\s*\|)+\s*\n//mg;
      "$pre$head\n$sep$rows|" . join("|", map { length ? " $_ " : " " } @v) . "|\n"
    }me;
    # A heading for the host under "## Host notes", when the note has that section.
    my $l = quotemeta $ENV{L};
    if (/^## Host notes[ \t]*$/m && !/^### $l[ \t]*$/m) {
      s{(^## Host notes[ \t]*\n)(.*?)(?=^## |\z)}{
        my ($h, $b) = ($1, $2); $b =~ s/\s+\z//;
        $h . ($b eq "" ? "\n" : "$b\n\n") . "### $ENV{L}\n\n"
      }sme;
    }' $note
}

# _dz_host_note_via <host> <pivot>: the Via column of that host's row in the Hosts table.
_dz_host_note_via() {
  local note
  note=$(_dz_note $BOX) && [[ -f $note ]] || return 0
  L=$1 VIA=$2 perl -0777 -pi -e '
    s{(^\#{2,3} Hosts[^\n]*\n(?:(?!\#{1,3} ).*\n)*?)(\|[^\n]*)\n(\|[ :-]*-[ |:-]*\|?[ \t]*\n)((?:\|[^\n]*\n)*)}{
      my ($pre, $head, $sep, $rows) = ($1, $2, $3, $4);
      my @h = map { s/^\s+|\s+$//gr } split /\|/, $head;
      my ($ih) = grep { $h[$_] =~ /^(hosts?|name|machine)$/i } 0..$#h;
      my ($iv) = grep { $h[$_] =~ /^(via|pivot)/i } 0..$#h;
      if (defined $ih && defined $iv) {
        $rows = join "", map {
          my @c = split /\|/, $_, -1;
          (($c[$ih] // "") =~ s/^\s+|\s+$//gr) eq $ENV{L}
            ? do { $c[$iv] = length $ENV{VIA} ? " $ENV{VIA} " : " "; join("|", @c) } : $_
        } split /^/m, $rows;
      }
      "$pre$head\n$sep$rows"
    }me' $note
}

# dz -t [host] [-ip <ip>] [-h <hosts>] [--via <pivot>|none] [--drop]
_dz_target() {
  emulate -L zsh
  local label=$1 ip=$2 hostarg=$3 drop=$4 via=$5 l v
  [[ -n $BOX ]] || { _dz_err E201 "no box loaded"; return 1 }
  _dz_box_read $DZ_ROOT/$BOX || { _dz_err E207 "box '$BOX' is gone (removed or archived?)"; return 1 }
  local main_ip=$reply[2] main_hosts=$reply[3] note
  note=$(_dz_note $BOX 2>/dev/null) || note=''
  local -a w

  # List
  if [[ -z $label ]]; then
    local mark
    [[ -z $_dz_ba ]] && mark='▶' || mark=' '
    printf '%s %-12s %-16s %-14s %s\n' $mark $BOX $main_ip "(main)" "$main_hosts"
    for l in $_dz_bh; do
      w=(${=l}); _dz_label_var $w[1]; v=$REPLY
      [[ $w[1] == $_dz_ba ]] && mark='▶' || mark=' '
      _dz_via_get $w[1]
      printf '%s %-12s %-16s %-14s %s\n' $mark $w[1] $w[2] "\$$v" "$w[3,-1]${REPLY:+  (via $REPLY)}"
    done
    (( $#_dz_bh )) || print "  no extra hosts yet: dz -t <host> -ip <ip>"
    return 0
  fi

  # The main host: only switching back to it, changes go through dz -ip / dz -h.
  if [[ $label == $BOX ]]; then
    [[ -z $ip && -z $hostarg && -z $drop && -z $via ]] ||
      { _dz_err E304 "$BOX is the main host, change it with dz -ip / dz -h (it has no pivot)"; return 1 }
    _dz_ba=''; _dz_host_save $main_ip "$main_hosts"
    _dz_load $BOX && print "• target: $BOX ($TARGET_IP)"
    return
  fi
  _dz_valid_label $label || { _dz_err E301 "host names are lowercase letters, digits and '-', like dc01"; return 1 }

  # Remove
  if [[ -n $drop ]]; then
    _dz_host_line $label || { _dz_err E302 "no host '$label' in $BOX"; return 1 }
    _dz_bh=("${(@)_dz_bh:#$label *}")
    _dz_via_set $label
    for l in $_dz_bh; do _dz_via_get ${l%% *} && [[ $REPLY == $label ]] && _dz_via_set ${l%% *}; done
    [[ $_dz_ba == $label ]] && _dz_ba=''
    _dz_host_save $main_ip "$main_hosts"
    local re; _dz_hosts_re $BOX/$label; re=$REPLY
    _dz_hosts_has $re && _dz_hosts_del $re
    [[ -f $note ]] && _dz_timeline_add $note "host $label removed"
    _dz_load $BOX && print "• host $label removed${DZ_ACTIVE:+, target is $DZ_ACTIVE}"
    return
  fi

  # Make active
  if [[ -z $ip && -z $hostarg && -z $via ]]; then
    _dz_host_line $label || { _dz_err E302 "no host '$label' in $BOX, add it with dz -t $label -ip <ip>"; return 1 }
    _dz_ba=$label; _dz_host_save $main_ip "$main_hosts"
    _dz_load $BOX && print "• target: $label ($TARGET_IP)"
    return
  fi

  # Add or change
  local old_ip='' old_hn='' new=1
  if _dz_host_line $label; then
    w=(${=REPLY}); old_ip=$w[2] old_hn="$w[3,-1]" new=0
  fi
  [[ -n $ip ]] || ip=$old_ip
  [[ -n $ip ]] || { _dz_err E303 "a new host needs -ip <ip>"; return 1 }
  if [[ -n $via && $via != none ]]; then
    [[ $via != $label ]] && { [[ $via == $BOX ]] || _dz_host_line $via } ||
      { _dz_err E305 "no host '$via' in $BOX to pivot through (dz -t lists them)"; return 1 }
  fi
  local old_via=''; _dz_via_get $label && old_via=$REPLY
  _dz_valid_ip $ip || { _dz_err E204 "'$ip' is not an IPv4 address"; return 1 }
  local -a hn=(${(s:,:)${hostarg// /,}})
  if [[ $hn == none ]]; then hn=()
  elif (( ! $#hn )); then hn=(${=old_hn})
  else
    for l in $hn; do _dz_valid_host $l || { _dz_err E205 "invalid hostname '$l'"; return 1 }; done
  fi
  _dz_bh=("${(@)_dz_bh:#$label *}" "$label $ip${hn:+ $hn}")
  _dz_host_save $main_ip "$main_hosts"
  [[ -n $via ]] && _dz_via_set $label ${via:#none}
  local new_via=''; _dz_via_get $label && new_via=$REPLY

  if [[ "$hn" != "$old_hn" || ( -n $old_hn && $ip != $old_ip ) ]]; then
    for l in $hn; do
      grep -vE "# dz:[^ ]+\$" $DZ_HOSTS 2>/dev/null | grep -qiE "[[:space:]]${l//./\\.}([[:space:]]|\$)" &&
        _dz_warn W203 "$l is already in $DZ_HOSTS outside dropzone"
    done
    _dz_hosts_set $BOX/$label $ip "$hn" &&
      if (( $#hn )); then print "• $DZ_HOSTS: $ip $hn"
      elif [[ -n $old_hn ]]; then print "• $DZ_HOSTS: line of $label removed"
      fi
  fi
  if [[ -f $note ]]; then
    if (( new )); then
      _dz_host_note $label $ip "${(j:, :)hn}" "$new_via"
      _dz_timeline_add $note "host $label added: $ip${hn:+ (${(j:, :)hn})}${new_via:+, via $new_via}"
    elif [[ $ip != $old_ip ]]; then
      _dz_note_ip $note $old_ip $ip >/dev/null
      _dz_timeline_add $note "host $label: new IP $ip"
    fi
    if (( ! new )) && [[ $new_via != $old_via ]]; then
      _dz_host_note_via $label "$new_via"
      _dz_timeline_add $note "host $label: ${new_via:+via $new_via}${new_via:-no pivot}"
    fi
  fi
  [[ $ip != $old_ip ]] && { _dz_vpn_check $ip; _dz_on DZ_PING && _dz_ping $ip }
  _dz_load $BOX
  _dz_label_var $label
  if (( new )); then print "• host $label added: \$$REPLY=$ip${new_via:+, via $new_via}  (dz -t $label makes it the target)"
  else print "• host $label: \$$REPLY=$ip${hn:+  $hn}${new_via:+  (via $new_via)}"
  fi
}
