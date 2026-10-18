# sysreptor: evidence to your SysReptor project, opt-in ('sysreptor = yes').
#
# dz -s (screenshots) and dz -e (command output) also go to the project's notes, under a
# note named after the box, with reptor (pip install reptor; set it up with 'reptor conf').
# The upload runs in the background and logs to logs/sysreptor.log. dropzone never makes
# findings or a report: that stays your work in SysReptor.

# _dz_reptor file <path> | _dz_reptor note <markdown>
_dz_reptor() {
  emulate -L zsh
  _dz_on DZ_SYSREPTOR && [[ -n $BOX ]] || return 0
  (( $+commands[reptor] )) || { _dz_warn W603 "reptor not found (pip install reptor, then reptor conf)"; return 0 }
  local log=$DZ_ROOT/$BOX/logs/sysreptor.log
  mkdir -p ${log:h}
  case $1 in
    file) ( reptor -n $BOX file $2 >> $log 2>&1 || print -r -- "upload failed: $2" >> $log ) &! ;;
    note) ( print -r -- $2 | reptor -n $BOX note >> $log 2>&1 || print -r -- "upload failed: note" >> $log ) &! ;;
  esac
  print "• sysreptor: uploading to note '$BOX' (${log/#$HOME/~})"
}
