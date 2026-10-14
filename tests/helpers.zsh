# Test helpers. Every test file runs in its own temporary HOME with a fake vault.

typeset -gi _t_pass=0 _t_fail=0

_t_setup() {
  # Clear everything that can point outside the temporary HOME (CI sets XDG_CONFIG_HOME).
  unset XDG_CONFIG_HOME XDG_CACHE_HOME DZ_CONFIG DZ_STATE BOX TARGET_IP DOMAIN NO_COLOR
  export HOME=$(mktemp -d) TMPHOME
  TMPHOME=$HOME
  # Never the real /etc/hosts: every test gets its own, writable hosts file.
  export DZ_HOSTS=$HOME/hosts
  print -r -- $'127.0.0.1\tlocalhost' > $DZ_HOSTS
  mkdir -p $HOME/vault/Templates $HOME/.config/dropzone
  print -r -- $'---\ntitle: "{{title}}"\nupdated: {{date}}\nstatus: active\nip: \n---\n| $TARGET_IP | | | |\nnmap $TARGET_IP\n' \
    > $HOME/vault/Templates/Box-note.md
  print -r -- "[notes]
vault = $HOME/vault
template = Templates/Box-note.md
[box]
ping = no
vpncheck = no
[menu]
animate = no" > $HOME/.config/dropzone/config
  source $1/dropzone.plugin.zsh
  cd $HOME
}

pass() { (( _t_pass++ )); print "  ✓ $1" }
fail() { (( _t_fail++ )); print "  ✗ $1" }

# ok <description> <command...>   command must succeed
ok()  { local d=$1; shift; "$@" >/dev/null 2>&1 && pass $d || fail $d }
# nok <description> <command...>  command must fail
nok() { local d=$1; shift; "$@" >/dev/null 2>&1 && fail $d || pass $d }
# eq <description> <expected> <actual>
eq()  { [[ $2 == $3 ]] && pass $1 || fail "$1 (expected '$2', got '$3')" }
# has <description> <part> <text>
has() { [[ $3 == *$2* ]] && pass $1 || fail "$1 ('$2' not found in: ${3[1,120]})" }

_t_done() {
  print "  $_t_pass passed, $_t_fail failed"
  rm -rf $TMPHOME
  (( _t_fail == 0 ))
}
