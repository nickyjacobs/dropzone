# prompt: the loaded box as a segment in your prompt.
#
#   PROMPT='...$(_dz_prompt 2>/dev/null)...'     (needs setopt prompt_subst)
#
# Prints "[jacops 10.129.42.190]-", "[jacops dc01 10.10.10.5]-" with another host as the
# target (dz -t), or nothing without a box or with 'prompt = no'.
# Runs for every prompt, so it uses no external commands.
_dz_prompt() {
  [[ -n $BOX ]] && _dz_on DZ_PROMPT || return 0
  local host=''
  [[ -n $DZ_ACTIVE ]] && host="%F{46}$DZ_ACTIVE%f "
  print -rn -- "[%B%F{46}$BOX%b%f $host%F{118}${TARGET_IP}%f]-"
}
