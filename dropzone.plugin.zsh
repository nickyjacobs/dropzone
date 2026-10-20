# dropzone: per-box tooling for Kali. Entry point following the Zsh Plugin Standard,
# so it also loads through oh-my-zsh, antidote, zinit or a plain source line.

0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
0=${${(M)0:#/*}:-$PWD/$0}

typeset -g _dz_repo=${0:A:h}
typeset -g _dz_version=$(<$_dz_repo/VERSION 2>/dev/null)
: ${_dz_version:=dev}

zmodload -F zsh/datetime b:strftime p:EPOCHSECONDS 2>/dev/null
autoload -Uz add-zsh-hook

# Error codes, arts and config first (the config reports with the codes and checks
# 'art' against the number of arts), then the rest of lib/.
source $_dz_repo/lib/errors.zsh
source $_dz_repo/lib/art.zsh
source $_dz_repo/lib/config.zsh
() {
  local f
  for f in $_dz_repo/lib/*.zsh(N); do
    [[ ${f:t} == (art|config|errors).zsh ]] || source $f
  done
}

# Convert boxes from older versions, load the last box, start recording if 'output = yes'.
_dz_migrate
_dz_autoload
_dz_record_start
