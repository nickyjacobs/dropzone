# Command log per box and the script(1) recording.

L=~/boxes/alpha/logs/commands.log
_dz_log_preexec "ls"
ok  "no log without a box" test ! -e ~/boxes/alpha

dz -n alpha -ip 10.10.10.1 >/dev/null
ok  "logs folder in a new box" test -d ~/boxes/alpha/logs
_dz_log_preexec "nmap -p- 10.10.10.1"
has "command logged" '$ nmap -p- 10.10.10.1' "$(cat $L)"
ok  "with date and time" grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}  ' $L
has "with folder" "~/boxes/alpha" "$(cat $L)"
_dz_log_preexec " echo secret"
nok "leading space: not logged" grep -q secret $L
DZ_LOG_COMMANDS=no _dz_log_preexec "whoami"
nok "commands = no: not logged" grep -q whoami $L
eq  "hook is in preexec" 1 "${preexec_functions[(I)_dz_log_preexec]:+1}"

# Box archived in another terminal: logging must not bring the folder back.
cd ~
dz -a alpha >/dev/null
BOX=alpha
_dz_log_preexec "whoami"
ok  "no ghost folder after archiving" test ! -e ~/boxes/alpha
unset BOX
dz -l alpha >/dev/null
eq  "archived box loads again" alpha "$BOX"
cd ~; dz -a alpha >/dev/null; mkdir -p ~/boxes/alpha
has "restore explains a blocking folder" "exists and is not a box" "$(dz -l alpha 2>&1)"
rmdir ~/boxes/alpha; dz -l alpha >/dev/null

ok  "no recording in a non-interactive shell" _dz_record_start
if script --version 2>/dev/null | grep -q util-linux; then
  _dz_record_cmd
  eq  "recording command is script" script "$reply[1]"
  has "recording in logs/" "/boxes/alpha/logs/" "$reply[5]"
  has "timing file next to it" ".timing" "$reply[7]"
else
  pass "recording command (skipped: no util-linux script)"
fi
nok "no recording command for a removed box" eval 'BOX=gone _dz_record_cmd'
has "--config show lists [log]" "[+] log" "$(dz --config show)"
