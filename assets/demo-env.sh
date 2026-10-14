#!/usr/bin/env bash
# Sets up a throwaway shell for assets/demo.tape: its own HOME, a writable hosts file
# and a short prompt. Used by .github/workflows/demo.yml.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
d=/tmp/dzdemo
mkdir -p $d/home/.config/dropzone
: > $d/hosts
printf '[box]\nping = no\n[menu]\nart = 1\n' > $d/home/.config/dropzone/config
cat > $d/.zshrc <<ZSHRC
unset XDG_CONFIG_HOME XDG_CACHE_HOME
export HOME=$d/home DZ_HOSTS=$d/hosts
setopt prompt_subst
source $repo/dropzone.plugin.zsh
PROMPT='%F{240}kali%f \$(_dz_prompt)%F{39}%~%f %F{46}❯%f '
cd ~
ZSHRC
