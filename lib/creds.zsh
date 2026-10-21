# creds: credentials per box. Off by default, turn on with 'creds = yes'.
#
#   dz -c <user> [source]            store, asks for the secret without echo
#   dz -c <user>:<secret> [source]   store, secret on the command line
#   dz -c                            list (▶ = active)
#   dz -c <nr>                       make another one active
#   dz -c [nr] --valid <host,...>    where the cred works (the active one without a number)
#   dz -c --export                   users, passwords and hashes to loot/ for spraying
#
# Storage: ~/boxes/<box>/creds (chmod 600), tab separated: user, secret, source, date and
# valid on (hosts, comma separated; older files have no fifth field).
# Active: $TARGET_USER plus $PASSWORD or $NT_HASH. Never $USER: that's your own login.
# A user like corp\alex or alex@corp.local sets $CRED_DOMAIN and $TARGET_USER=alex.
# A secret that is a file sets $SSH_KEY (a private key) or $KRB5CCNAME (a .ccache ticket).

_dz_creds_file() { REPLY=$DZ_ROOT/$BOX/creds }

# Classify a secret: NT hash (32 hex, or LM:NT), SSH key or Kerberos ticket (a file, stored
# with its full path), or password. Sets reply=(kind value).
_dz_creds_kind() {
  local s=$1
  if [[ $s == /* && -f $s ]]; then
    if [[ $s == *.ccache ]]; then reply=(ticket $s)
    elif grep -q 'PRIVATE KEY' $s 2>/dev/null; then reply=(key $s)
    else reply=(password $s)
    fi
  elif [[ $s =~ '^[0-9A-Fa-f]{32}$' ]]; then reply=(hash $s)
  elif [[ $s =~ '^[0-9A-Fa-f]{32}:[0-9A-Fa-f]{32}$' ]]; then reply=(hash ${s#*:})
  else reply=(password $s)
  fi
}

# $SSH_KEY and $KRB5CCNAME go only when dz set them: you often export KRB5CCNAME yourself.
_dz_creds_unset_files() {
  [[ -n $_dz_set_key && ${SSH_KEY-} == $_dz_set_key ]] && unset SSH_KEY
  [[ -n $_dz_set_tgt && ${KRB5CCNAME-} == $_dz_set_tgt ]] && unset KRB5CCNAME
  typeset -g _dz_set_key='' _dz_set_tgt=''
}

# Export cred number $1 (or the active one, or the last one) from the file.
_dz_creds_export() {
  emulate -L zsh
  unset TARGET_USER PASSWORD NT_HASH CRED_DOMAIN
  _dz_creds_unset_files
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
  case $reply[1] in
    hash)   typeset -gx NT_HASH=$reply[2] ;;
    key)    typeset -gx SSH_KEY=$reply[2]; _dz_set_key=$reply[2] ;;
    ticket) typeset -gx KRB5CCNAME=$reply[2]; _dz_set_tgt=$reply[2] ;;
    *)      typeset -gx PASSWORD=$reply[2] ;;
  esac
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
  [[ -s $f ]] && (( $1 >= 1 && $1 <= $#all )) || { _dz_err E502 "no cred #$1"; return 1 }
  local -a c=("${(@ps:\t:)all[$1]}") add=(${(s:,:)${2// /,}}) known
  _dz_box_read $DZ_ROOT/$BOX 2>/dev/null && known=($BOX ${_dz_bh%% *})
  for h in $add; do
    _dz_valid_label $h || _dz_valid_ip $h || { _dz_err E503 "'$h' is not a host name or IP"; return 1 }
    _dz_valid_ip $h || (( $known[(Ie)$h] )) || _dz_warn W501 "$h is not a host of $BOX (dz -t adds it)"
  done
  local -a v=(${(s:,:)c[5]}); v=(${(u)v} $add); v=(${(u)v})
  c[5]=${(j:,:)v}
  all[$1]=${(pj:\t:)c}
  ( umask 077; print -rl -- $all > $f )
  _dz_creds_valid_note "$c[1]" "$c[2]" "${(j:, :)v}"
  print -r -- "• cred #$1 ($c[1]) valid on: ${(j:, :)v}"
}

# dz -c --export: every user, password and NT hash of the box in loot/, one per line and
# no doubles, for your own nxc / kerbrute runs. Made again on every call.
_dz_creds_dump() {
  emulate -L zsh
  local f=$DZ_ROOT/$BOX/creds dir=$DZ_ROOT/$BOX/loot l u
  [[ -s $f ]] || { _dz_err E504 "no creds for $BOX yet"; return 1 }
  local -a c users=() pass=() hashes=()
  for l in "${(@f)$(<$f)}"; do
    c=("${(@ps:\t:)l}")
    u=${${c[1]#*\\}%@*}
    users+=($u)
    _dz_creds_kind $c[2]
    case $reply[1] in
      hash)     hashes+=($reply[2]) ;;
      password) pass+=($reply[2]) ;;
    esac
  done
  mkdir -p $dir || return 1
  users=(${(u)users}) pass=(${(u)pass}) hashes=(${(u)hashes})
  ( umask 077
    : > $dir/users.txt; : > $dir/passwords.txt; : > $dir/hashes.txt
    (( $#users )) && print -rl -- $users > $dir/users.txt
    (( $#pass )) && print -rl -- $pass > $dir/passwords.txt
    (( $#hashes )) && print -rl -- $hashes > $dir/hashes.txt )
  print "• ${dir/#$HOME/~}/: users.txt ($#users), passwords.txt ($#pass), hashes.txt ($#hashes)"
}

# dz -c ...
_dz_creds() {
  emulate -L zsh
  _dz_on DZ_CREDS || { _dz_err E501 "creds is off. Set 'creds = yes' in your config (dz --config)"; return 1 }
  [[ -n $BOX ]] || { _dz_err E201 "no box loaded"; return 1 }
  _dz_creds_file; local f=$REPLY valid=$3
  [[ $4 == 1 ]] && { _dz_creds_dump; return }

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
    [[ -s $f ]] && (( $1 <= $#all )) || { _dz_err E502 "no cred #$1"; return 1 }
    _dz_creds_export $1 && print -r -- "• active: $TARGET_USER (#$1)"
    return 0
  fi

  local u s src=$2 ts
  if [[ $1 == *:* ]]; then
    u=${1%%:*} s=${1#*:}
  else
    # Only a user: ask for the secret, so it stays out of your history and ps.
    [[ -t 0 ]] || { _dz_err E505 "use dz -c <user>:<secret> [source], or run it in a terminal"; return 1 }
    u=$1
    read -rs "s?Secret for $u: " || { print; return 1 }
    print
  fi
  [[ -n $u && -n $s ]] || { _dz_err E506 "user and secret can't be empty"; return 1 }
  # A key or ticket file (a path with a /, or a .ccache) is stored with its full path.
  if [[ $s == */* || $s == *.ccache ]]; then
    if [[ -f $s ]]; then s=${s:A}
    elif [[ -f $DZ_ROOT/$BOX/$s ]]; then s=$DZ_ROOT/$BOX/$s
    fi
  fi
  [[ $u$s$src == *[$'\t\n']* ]] && { _dz_err E507 "no tabs or newlines in creds"; return 1 }
  ts=$(date +%F)
  ( umask 077; print -r -- "$u"$'\t'"$s"$'\t'"$src"$'\t'"$ts" >> $f )
  chmod 600 $f
  local -a all=("${(@f)$(<$f)}")
  local -i n=$#all
  _dz_creds_export $n
  _dz_creds_note "${src:--}" "$u" "$s"
  if [[ -n $NT_HASH ]]; then print -r -- "• cred #$n stored: $u (NT hash) → \$TARGET_USER, \$NT_HASH"
  elif [[ -n $SSH_KEY ]]; then print -r -- "• cred #$n stored: $u (SSH key) → \$TARGET_USER, \$SSH_KEY"
  elif [[ -n $KRB5CCNAME ]]; then print -r -- "• cred #$n stored: $u (ticket) → \$TARGET_USER, \$KRB5CCNAME"
  else print -r -- "• cred #$n stored: $u → \$TARGET_USER, \$PASSWORD"
  fi
  [[ -n $CRED_DOMAIN ]] && print -r -- "  domain: $CRED_DOMAIN → \$CRED_DOMAIN"
  [[ -z $valid ]] || _dz_creds_valid $n $valid
}
