# creds: credentials per box. Off by default, turn on with 'creds = yes'.
#
#   dz -c <user> [source]            store, asks for the secret without echo
#   dz -c <user>:<secret> [source]   store, secret on the command line
#   dz -c                            list (▶ = active)
#   dz -c <nr>                       make another one active
#   dz -c [nr] --valid <host,...>    where the cred works (the active one without a number)
#
# Storage: ~/boxes/<box>/creds (chmod 600), tab separated: user, secret, source, date and
# valid on (hosts, comma separated; older files have no fifth field).
# Active: $TARGET_USER plus $PASSWORD or $NT_HASH. Never $USER: that's your own login.
# A user like corp\alex or alex@corp.local sets $CRED_DOMAIN and $TARGET_USER=alex.

_dz_creds_file() { REPLY=$DZ_ROOT/$BOX/creds }

# Classify a secret: NT hash (32 hex, or LM:NT) or password. Sets reply=(kind value).
_dz_creds_kind() {
  local s=$1
  if [[ $s =~ '^[0-9A-Fa-f]{32}$' ]]; then reply=(hash $s)
  elif [[ $s =~ '^[0-9A-Fa-f]{32}:[0-9A-Fa-f]{32}$' ]]; then reply=(hash ${s#*:})
  else reply=(password $s)
  fi
}

# Export cred number $1 (or the active one, or the last one) from the file.
_dz_creds_export() {
  emulate -L zsh
  unset TARGET_USER PASSWORD NT_HASH CRED_DOMAIN
  _dz_on DZ_CREDS && [[ -n $BOX && -d $DZ_ROOT/$BOX ]] || return 0
  _dz_creds_file; local f=$REPLY
  [[ -s $f ]] || return 0
  local -a lines=("${(@f)$(<$f)}")
  local -i n=${1:-$(<$DZ_ROOT/$BOX/.creds-current 2>/dev/null)}
  (( n >= 1 && n <= $#lines )) || n=$#lines
  local -a c=("${(@ps:\t:)lines[n]}")
  if [[ $c[1] == ?*\\?* ]]; then typeset -gx CRED_DOMAIN=${c[1]%%\\*} TARGET_USER=${c[1]#*\\}
  elif [[ $c[1] == ?*@?* ]]; then typeset -gx CRED_DOMAIN=${c[1]##*@} TARGET_USER=${c[1]%@*}
  else typeset -gx TARGET_USER=$c[1]
  fi
  _dz_creds_kind $c[2]
  if [[ $reply[1] == hash ]]; then typeset -gx NT_HASH=$reply[2]; else typeset -gx PASSWORD=$reply[2]; fi
  print $n > $DZ_ROOT/$BOX/.creds-current
}

# Add a row to the Credentials table in the note (the empty example row goes).
_dz_creds_note() {
  local note
  note=$(_dz_note $BOX) && [[ -f $note ]] || return 0
  SRC=$1 U=$2 SEC=$3 perl -0777 -pi -e '
    my ($s,$u,$p) = map { (my $x = $_) =~ s/\|/\\|/g; $x } @ENV{qw(SRC U SEC)};
    s{(^\#\# Credentials[^\n]*\n(?:(?!\#\# ).*\n)*?\|[ -]*---[^\n]*\n)((?:\|[^\n]*\n)*)}{
      my ($head,$rows) = ($1,$2);
      $rows =~ s/^\|(?:\s*\|)+\s*\n//mg;
      "$head$rows| $s | $u | $p | | |\n"
    }me' $note
}

# _dz_creds_valid_note <user> <secret> <hosts>: fill the Valid on column of that cred's
# row in the Credentials table. Columns are found by name, so your own template works.
_dz_creds_valid_note() {
  local note
  note=$(_dz_note $BOX) && [[ -f $note ]] || return 0
  U=$1 SEC=$2 V=$3 perl -0777 -pi -e '
    my ($u,$p) = map { (my $x = $_) =~ s/\|/\\|/g; $x } @ENV{qw(U SEC)};
    s{(^\#\# Credentials[^\n]*\n(?:(?!\#\# ).*\n)*?)(\|[^\n]*)\n(\|[ -]*---[^\n]*\n)((?:\|[^\n]*\n)*)}{
      my ($pre,$head,$sep,$rows) = ($1,$2,$3,$4);
      my @h = map { s/^\s+|\s+$//gr } split /(?<!\\)\|/, $head;
      my ($iu) = grep { $h[$_] =~ /user/i } 0..$#h;
      my ($is) = grep { $h[$_] =~ /secret|pass|hash|wachtwoord/i } 0..$#h;
      my ($iv) = grep { $h[$_] =~ /valid|geldig|works/i } 0..$#h;
      if (defined $iu && defined $is && defined $iv) {
        $rows = join "", map {
          my @c = split /(?<!\\)\|/, $_, -1;
          (($c[$iu] // "") =~ s/^\s+|\s+$//gr) eq $u && (($c[$is] // "") =~ s/^\s+|\s+$//gr) eq $p
            ? do { $c[$iv] = " $ENV{V} "; join("|", @c) } : $_
        } split /^/m, $rows;
      }
      "$pre$head\n$sep$rows"
    }me' $note
}

# _dz_creds_valid <nr> <host,...>: add hosts to where cred <nr> works.
_dz_creds_valid() {
  emulate -L zsh
  local f=$DZ_ROOT/$BOX/creds h
  local -a all=("${(@f)$(<$f 2>/dev/null)}")
  [[ -s $f ]] && (( $1 >= 1 && $1 <= $#all )) || { print -u2 "dz: no cred #$1"; return 1 }
  local -a c=("${(@ps:\t:)all[$1]}") add=(${(s:,:)${2// /,}}) known
  _dz_box_read $DZ_ROOT/$BOX 2>/dev/null && known=($BOX ${_dz_bh%% *})
  for h in $add; do
    _dz_valid_label $h || _dz_valid_ip $h || { print -u2 "dz: '$h' is not a host name or IP"; return 1 }
    _dz_valid_ip $h || (( $known[(Ie)$h] )) || print -u2 "• note: $h is not a host of $BOX (dz -t adds it)"
  done
  local -a v=(${(s:,:)c[5]}); v=(${(u)v} $add); v=(${(u)v})
  c[5]=${(j:,:)v}
  all[$1]=${(pj:\t:)c}
  ( umask 077; print -rl -- $all > $f )
  _dz_creds_valid_note "$c[1]" "$c[2]" "${(j:, :)v}"
  print "• cred #$1 ($c[1]) valid on: ${(j:, :)v}"
}

# dz -c ...
_dz_creds() {
  emulate -L zsh
  _dz_on DZ_CREDS || { print -u2 "dz: creds is off. Set 'creds = yes' in your config (dz --config)"; return 1 }
  [[ -n $BOX ]] || { print -u2 "dz: no box loaded"; return 1 }
  _dz_creds_file; local f=$REPLY valid=$3

  if [[ -n $valid && ( -z $1 || $1 == <1-> ) ]]; then   # where it works
    _dz_creds_valid ${1:-$(<$DZ_ROOT/$BOX/.creds-current 2>/dev/null)} $valid
    return
  fi

  if [[ -z $1 ]]; then                                   # list
    [[ -s $f ]] || { print "no creds for $BOX"; return 0 }
    local -i i=0 cur=$(<$DZ_ROOT/$BOX/.creds-current 2>/dev/null)
    local line; local -a c
    for line in "${(@f)$(<$f)}"; do
      (( i++ )); c=("${(@ps:\t:)line}")
      printf '%s %2d  %-24s %-34s %s\n' "$( (( i == cur )) && print '▶' || print ' ')" $i "$c[1]" "$c[2]" \
        "${c[3]:+($c[3])}${c[5]:+ → ${c[5]//,/, }}"
    done
    return 0
  fi

  if [[ $1 == <1-> ]]; then                              # make active
    local -a all=("${(@f)$(<$f 2>/dev/null)}")
    [[ -s $f ]] && (( $1 <= $#all )) || { print -u2 "dz: no cred #$1"; return 1 }
    _dz_creds_export $1 && print "• active: $TARGET_USER (#$1)"
    return 0
  fi

  local u s src=$2 ts
  if [[ $1 == *:* ]]; then
    u=${1%%:*} s=${1#*:}
  else
    # Only a user: ask for the secret, so it stays out of your history and ps.
    [[ -t 0 ]] || { print -u2 "dz: use dz -c <user>:<secret> [source], or run it in a terminal"; return 1 }
    u=$1
    read -rs "s?Secret for $u: " || { print; return 1 }
    print
  fi
  [[ -n $u && -n $s ]] || { print -u2 "dz: user and secret can't be empty"; return 1 }
  [[ $u$s$src == *[$'\t\n']* ]] && { print -u2 "dz: no tabs or newlines in creds"; return 1 }
  ts=$(date +%F)
  ( umask 077; print -r -- "$u"$'\t'"$s"$'\t'"$src"$'\t'"$ts" >> $f )
  chmod 600 $f
  local -a all=("${(@f)$(<$f)}")
  local -i n=$#all
  _dz_creds_export $n
  _dz_creds_note "${src:--}" "$u" "$s"
  if [[ -n $NT_HASH ]]; then print "• cred #$n stored: $u (NT hash) → \$TARGET_USER, \$NT_HASH"
  else print "• cred #$n stored: $u → \$TARGET_USER, \$PASSWORD"
  fi
  [[ -n $CRED_DOMAIN ]] && print "  domain: $CRED_DOMAIN → \$CRED_DOMAIN"
  [[ -z $valid ]] || _dz_creds_valid $n $valid
}
