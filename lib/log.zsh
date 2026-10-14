# log: record what you do per box, for your report.
#
#   commands = yes   every command with date, time and folder in logs/commands.log.
#                    Start a command with a space to keep it out of the log.
#   output = yes     full terminal output with script(1) in logs/<date>_<time>.log,
#                    in every new terminal with a loaded box.

# Log folder of the loaded box in $REPLY. Fails when the box is gone (removed or
# archived in another terminal), so logging never brings a box folder back.
_dz_log_dir() {
  [[ -n $BOX && -f $DZ_ROOT/$BOX/.dropzone ]] || return 1
  REPLY=$DZ_ROOT/$BOX/logs
  [[ -d $REPLY ]] || mkdir -p $REPLY
}

_dz_log_preexec() {
  emulate -L zsh
  [[ -n $BOX ]] && _dz_on DZ_LOG_COMMANDS || return 0
  [[ $1 == ' '* ]] && return 0
  _dz_log_dir || return 0
  local cmd=$1 dir=$REPLY ts
  # No secrets in the log: everything after 'dz ... -c' or '--creds' is hidden.
  if [[ $cmd =~ '(^|[;&|[:space:]])dz([[:space:]][^;&|]*)?[[:space:]](-c|--creds)([[:space:]]|$)' ]] &&
     (( MEND < $#cmd )); then
    cmd="${cmd[1,MEND]}<hidden>"
  fi
  strftime -s ts '%F %T' $EPOCHSECONDS
  print -r -- "$ts  ${PWD/#$HOME/~}  \$ $cmd" >> $dir/commands.log
}
add-zsh-hook preexec _dz_log_preexec

# The script(1) command for a recording in $reply, or fail when it can't (util-linux only).
_dz_record_cmd() {
  emulate -L zsh
  script --version 2>/dev/null | grep -q util-linux || return 1
  _dz_log_dir || return 1
  local ts; strftime -s ts '%F_%H%M%S' $EPOCHSECONDS
  reply=(script -q -f -O $REPLY/$ts.log -T $REPLY/$ts.timing -c ${commands[zsh]:-zsh})
}

# At terminal start: record if that's on. The recording runs a new zsh, and DZ_RECORDING
# keeps that one from recording again. No exec: if script can't start, this shell
# carries on without a recording instead of the terminal closing.
_dz_record_start() {
  [[ -o interactive && -t 0 && -t 1 && -n $BOX && -z $DZ_RECORDING ]] || return 0
  _dz_on DZ_LOG_OUTPUT && _dz_record_cmd || return 0
  local log=$reply[5]
  DZ_RECORDING=$log "${reply[@]}"
  [[ -e $log ]] && exit
  print -u2 "dz: recording didn't start, carrying on without it"
}
