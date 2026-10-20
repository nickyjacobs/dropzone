#!/usr/bin/env bash
# Sets up a throwaway shell for the assets/*.tape demos: its own HOME and a short prompt.
# Used by .github/workflows/demo.yml, on a throwaway runner: /etc/hosts is the real one
# (passwordless sudo there), and a VPN is faked with a fixed tun0 IP.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
d=/tmp/dzdemo
mkdir -p $d/home/.config/dropzone
printf '[box]\nping = no\nvpncheck = no\n[notes]\nflag_goal = 14\n[menu]\nart = 1\n' > $d/home/.config/dropzone/config
cat > $d/.zshrc <<ZSHRC
unset XDG_CONFIG_HOME XDG_CACHE_HOME
export HOME=$d/home
setopt prompt_subst
source $repo/dropzone.plugin.zsh
# No VPN on the runner: tun0 has a fixed IP in the demos.
_dz_attacker_ip() { print 10.10.14.7 }
# A stand-in for nxc, so dz -e has output to save.
nxc() {
  print 'SMB  10.129.42.190  445  JACOPS  [*] Windows Server 2019 (name:JACOPS) (domain:jacops.htb) (signing:False)'
  print 'SMB  10.129.42.191  445  DC01    [*] Windows Server 2019 (name:DC01) (domain:jacops.htb) (signing:True)'
}
PROMPT='%F{240}kali%f \$(_dz_prompt)%F{39}%~%f %F{46}❯%f '
cd ~
ZSHRC
