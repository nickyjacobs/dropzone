# errors: every error (E) and warning (W) has a code. The message on screen is short;
# 'dz --explain <code>' and docs/errors.md say why it happens and what to do.
#
#   E1xx using dz       E2xx boxes        E3xx hosts (dz -t)     E4xx notes, flags, evidence
#   E5xx creds          E6xx tools, ports E7xx setup, update     E8xx deadline
#
# An error stops the command (exit 1). A warning tells you something and carries on.
# docs/errors.md is made from this file: zsh scripts/errors-doc.zsh > docs/errors.md

# _dz_err <code> <message>: 'dz [E201] no box loaded' on stderr.
_dz_err() { print -ru2 -- "dz [$1] $2" }
# _dz_warn <code> <message>: '• [W201] ...' on stderr.
_dz_warn() { print -ru2 -- "• [$1] $2" }

typeset -gA _dz_err_title _dz_err_why _dz_err_fix

# _dz_def <code> <title> <why> <fix>
_dz_def() { _dz_err_title[$1]=$2 _dz_err_why[$1]=$3 _dz_err_fix[$1]=$4 }

# --- E1xx: using dz
_dz_def E101 "unknown option" \
  "dz doesn't know this option. Often a typo, or an option from a newer version than the one you have." \
  "Check the spelling with 'dz --help'. Options are case sensitive: -ip, not -IP."
_dz_def E102 "option needs a value" \
  "The option takes a value (a name, an IP, a file), but nothing followed it, or the next word starts with '-' and reads as another option." \
  "Put the value right after the option: 'dz -l jacops', 'dz -ip 10.10.10.5'. Quote values that contain spaces."
_dz_def E103 "more than one action" \
  "Every dz call does one thing: -n, -l, -v, -i, -x, -t, -p, -cp, -o, -d, -a, -f, -j, -s, -e, -g, -c or -r. Two of them in one call are refused, so nothing half happens." \
  "Split it into two calls: 'dz -l jacops' and then 'dz -i'. Options like -ip, -h, --via and --template are not actions and can go along."
_dz_def E104 "no action given" \
  "The call has options but none of them says what to do, for example only '-y' or '--all'." \
  "Add the action: 'dz -v --all', 'dz -r jacops -y'. 'dz' alone opens the menu."
_dz_def E105 "-ip / -h without a box action" \
  "-ip and -h change a box. Without -n or -l they change the loaded box; with another action (like -d) dz doesn't know what you mean." \
  "Use 'dz -ip <ip>' for the loaded box, 'dz -l <name> -ip <ip>' for another one, or 'dz -n <name> -ip <ip>' for a new one."
_dz_def E106 "new box without an IP" \
  "A box always has a target IP: it goes into \$TARGET_IP, the note and /etc/hosts." \
  "Give it: 'dz -n jacops -ip 10.129.42.190'."
_dz_def E107 "the menu needs a terminal" \
  "The menu reads keys from a terminal. In a script, a pipe or 'zsh -c' there is none." \
  "Use the options instead of the menu (dz --help), or run dz in a normal terminal."
_dz_def E108 "removing needs a confirmation" \
  "dz -r asks before it removes a box, and there is no terminal to ask in (a script or a pipe)." \
  "Add -y to skip the question, and --note or --keep-note for the note: 'dz -r jacops -y --keep-note'."

# --- E2xx: boxes
_dz_def E201 "no box loaded" \
  "This command works on the loaded box, and no box is loaded in this terminal: you never loaded one, ran dz -x, or removed it." \
  "Load one with 'dz -l <name>' (dz -v lists them), or make one with 'dz -n <name> -ip <ip>'."
_dz_def E202 "no such box" \
  "There is no box folder with that name under your boxes folder (~/boxes by default). It may be a typo, archived, removed, or in another 'boxes' folder from your config." \
  "See what's there with 'dz -v --all'. An archived box comes back with 'dz -l <name>'."
_dz_def E203 "invalid box name" \
  "Box names start with a letter or digit and only have letters, digits, '.', '_' and '-'. That keeps names safe as folder names and in /etc/hosts tags." \
  "Pick a name like 'jacops', 'cpts-exam' or 'ms01_lab'."
_dz_def E204 "not an IPv4 address" \
  "dz takes IPv4 addresses (four numbers from 0 to 255). A hostname, a CIDR range or an IPv6 address is not accepted as a target IP." \
  "Give the IP: '-ip 10.129.42.190'. Hostnames go after -h."
_dz_def E205 "invalid hostname" \
  "A hostname for /etc/hosts starts with a letter or digit and has only letters, digits, '-' and '.', like dc01.corp.local. Spaces, underscores, slashes or a scheme (http://) don't fit in a hosts line." \
  "Fix the name, separate more names with commas: '-h dc01.corp.local,corp.local'."
_dz_def E206 "can't write the box folder" \
  "dz couldn't make the box folder or its .dropzone file: the boxes folder isn't writable, the disk is full, or the path in 'boxes' points somewhere you can't write." \
  "Check 'dz --config show' for the boxes folder and that you own it: ls -ld ~/boxes."
_dz_def E207 "the loaded box is gone" \
  "This terminal still has a box loaded, but its folder is gone: removed or archived in another terminal." \
  "Unload it with 'dz -x', or bring it back with 'dz -l <name>' if it was archived."
_dz_def E208 "archive folder already exists" \
  "dz -a moves the box to _archive/<name>, but a folder with that name is already there, from an earlier box with the same name." \
  "Look at the old one in ~/boxes/_archive/ and move or remove it, then archive again."
_dz_def E209 "can't restore: the folder is in the way" \
  "The box is archived, and dz -l wants to move it back to ~/boxes/<name>, but a folder with that name exists there and isn't a box." \
  "Move that folder away, then run 'dz -l <name>' again."
_dz_def W201 "VPN interface missing" \
  "The interface from 'iface' (tun0 by default) doesn't exist: your VPN isn't connected, or it uses another name. \$ATTACKER_IP stays empty." \
  "Connect your VPN. Another name (tun1, wg0)? Set 'iface' with dz --config. 'vpncheck = no' turns the check off."
_dz_def W202 "target not routed through the VPN" \
  "Your Kali would reach the target over another interface than the VPN (or a pivot from 'pivot'). Mostly a wrong IP, a VPN that isn't up, or a route from another network winning." \
  "Check the IP and 'ip route get <ip>'. A host behind a pivot? Make sure its interface matches 'pivot' (default ligolo*)."
_dz_def W203 "hostname already in /etc/hosts" \
  "The hostname is also on a line in /etc/hosts that dz didn't write. Which IP wins depends on the order, so the name can point to an old target." \
  "Remove or fix the old line in /etc/hosts (sudo nano /etc/hosts)."
_dz_def W204 "no note template, no note" \
  "dz couldn't find a note template, so the box has no note. Notes for flags, timeline and creds need one." \
  "Check 'template' with dz --config show, or put your template in ~/.config/dropzone/templates/box-note.md, then run the same dz -n again: it adds the note."
_dz_def W205 "template not found" \
  "The template from 'template' in your config or from --template doesn't exist where dz looked. A relative path is inside your vault (notes = vault) or ~/.config/dropzone." \
  "Check the path, or the name: --template exam looks for exam.md, exam-note.md or Exam-note.md."
_dz_def W206 "no note, status not set" \
  "The status (active/done) lives in the note's frontmatter, and this box has no note." \
  "Make the note (W204), or ignore it: the box folder is fine."

# --- E3xx: hosts (dz -t)
_dz_def E301 "invalid host name" \
  "Host names in a box (dz -t) become variables like \$DC01_IP, so they are lowercase letters, digits and '-'." \
  "Use names like dc01, ms01, web-02."
_dz_def E302 "no such host in the box" \
  "The box has no host with that name. 'dz -t' lists them; the main host is the box name itself." \
  "Add it first: 'dz -t <host> -ip <ip>'."
_dz_def E303 "new host without an IP" \
  "A host needs an IP to get its \$<HOST>_IP and its hosts line." \
  "'dz -t dc01 -ip 10.10.10.5'."
_dz_def E304 "the main host is changed with -ip / -h" \
  "The main host is the box itself. dz -t only switches back to it; its IP and hostnames change with dz -ip and dz -h, and as the entry point it has no pivot." \
  "'dz -ip <ip>' or 'dz -h <host,...>' for the main host."
_dz_def E305 "pivot not in the box" \
  "--via names the host this one sits behind, so that host must be in the box, and can't be the host itself." \
  "Add the pivot first ('dz -t web01 -ip <its internal IP>'), then 'dz -t ms01 --via web01'."

# --- E4xx: notes, flags, screenshots, evidence
_dz_def E401 "notes are off" \
  "'notes = off' in your config, so there is no note to open or write to." \
  "Set 'notes = folder' or 'notes = vault' with dz --config."
_dz_def E402 "the box has no note" \
  "The note file isn't where dz expects it: it was never made (W204), was moved or renamed, or 'notes'/'vault' changed in your config." \
  "Check the path in the message. Run the same 'dz -n <name> -ip <ip>' again to make a missing note."
_dz_def E403 "a flag has no spaces" \
  "Flags are one word (HTB flags are 32 hex characters). Spaces mean a copy-paste went wrong." \
  "Copy the flag again: 'dz -f 3f9a...e1'."
_dz_def E404 "host name instead of a flag" \
  "You gave a host name and no flag, so dz would store the host name as a flag." \
  "Give both: 'dz -f dc01 <flag>'."
_dz_def E405 "flag already stored" \
  "The same flag is already in the note. It's either a double paste or the same flag on two hosts." \
  "'dz -f' lists the flags. Change the note by hand if something is wrong."
_dz_def E406 "flag slot already filled" \
  "A single box has one user and one root slot, and that slot (or both) has a flag. dz never overwrites a flag." \
  "Look with 'dz -f'. A wrong flag: fix it in the note. More flags? Add hosts (dz -t) and use 'dz -f <host> <flag>'."
_dz_def E407 "flag for an unknown host" \
  "Flags per host go to a host of the box, and this one isn't there." \
  "'dz -t' lists the hosts; add it with 'dz -t <host> -ip <ip>'."
_dz_def E408 "couldn't place the flag" \
  "dz wrote the flag but couldn't find it back in the note: the Flags section has a layout dz doesn't know." \
  "Use the layout from the bundled template (- **User flag:** lines) or the Obsidian callouts in examples/obsidian/, or a Flags section with a plain list."
_dz_def E409 "no screenshot tool" \
  "dz -s needs a screenshot tool, and none was found (or the one from 'screenshot' isn't installed). On X11: xfce4-screenshooter, flameshot, gnome-screenshot, spectacle or ImageMagick's import. On Wayland: grim with slurp, spectacle, gnome-screenshot or flameshot." \
  "Install one: 'sudo apt install flameshot', on Wayland 'sudo apt install grim slurp'. Or set 'screenshot = auto'."
_dz_def E410 "no desktop for a screenshot" \
  "There is no graphical session (DISPLAY / WAYLAND_DISPLAY), for example over SSH." \
  "Take the screenshot in your desktop session (RDP, VNC, the VM window), or save output with 'cmd | dz -e'."
_dz_def E411 "nothing piped into dz -e" \
  "dz -e saves what a command prints, so it needs a pipe. Typed alone, there's nothing to read." \
  "'nxc smb \$TARGET | dz -e smb signing'."
_dz_def E412 "no output to save" \
  "The command in front of dz -e printed nothing to stdout. Many tools print errors to stderr, which a pipe doesn't carry." \
  "Add 2>&1 to the command: 'cmd 2>&1 | dz -e caption'."
_dz_def W401 "unusual flag format" \
  "HTB flags are 32 hex characters; this one isn't. It's stored anyway, because other platforms use other formats." \
  "Nothing, if it's right. Otherwise fix it in the note."
_dz_def W402 "terminal recording didn't start" \
  "'output = yes' records every new terminal with script(1), and that failed (no util-linux script, or no log folder). The terminal works without a recording." \
  "Check 'script --version' (needs util-linux) or set 'output = no'."

# --- E5xx: creds
_dz_def E501 "creds is off" \
  "Storing creds is opt-in, because they land in plain text in the box folder and the note." \
  "Set 'creds = yes' with dz --config."
_dz_def E502 "no such cred" \
  "There is no cred with that number in this box. Numbers are the order you stored them in." \
  "'dz -c' lists the creds with their numbers."
_dz_def E503 "invalid host for --valid" \
  "--valid takes host names (like dc01) or IPs, separated by commas." \
  "'dz -c 2 --valid dc01,ms01'."
_dz_def E504 "no creds to export" \
  "dz -c --export writes the creds of the box to loot/, and the box has none yet." \
  "Store one first: 'dz -c <user> <source>'."
_dz_def E505 "secret prompt needs a terminal" \
  "'dz -c <user>' asks for the secret without showing it, which needs a terminal. In a script or pipe there's none." \
  "Use 'dz -c <user>:<secret> [source]', and start the line with a space to keep it out of your history."
_dz_def E506 "empty user or secret" \
  "A cred needs both: 'user:secret'. One of them is empty, often from a ':' at the start or the end." \
  "'dz -c alex:Welcome1 smb-share'."
_dz_def E507 "tab or newline in a cred" \
  "The creds file uses tabs between the fields, so a tab or newline inside a user, secret or source would break it." \
  "Remove the tab or newline (it usually comes from a bad copy)."
_dz_def W501 "host not in the box" \
  "The cred is marked as valid on a host that isn't in the box (dz -t). It's stored anyway." \
  "Add the host with 'dz -t <host> -ip <ip>' if you want its IP and variables."

# --- E6xx: tools and ports
_dz_def E601 "VPN interface down, no IP" \
  "This command needs your IP on the VPN (for download commands or to copy), and the 'iface' interface has none." \
  "Connect the VPN, or set 'iface' to the right interface with dz --config."
_dz_def E602 "--via needs a pivot" \
  "dz serve --via takes the pivot: a host of the box or an IP." \
  "'dz serve ~/tools --via web01' or '--via 172.16.5.15'."
_dz_def E603 "unknown pivot for dz serve" \
  "The pivot after --via isn't an IP and not a host of the loaded box." \
  "Give its internal IP, or add it: 'dz -t web01 -ip 172.16.5.15'."
_dz_def E604 "SMB through a pivot" \
  "Windows only talks SMB on port 445, and the pivot uses that port itself, so a ligolo listener can't forward it." \
  "Use HTTP: 'dz serve --via <pivot>'."
_dz_def E605 "no such folder to serve" \
  "The folder doesn't exist, as a path or as a subfolder of the loaded box." \
  "Check the path; 'dz serve exploits' serves the box's exploits/ folder."
_dz_def E606 "folder holds your box files" \
  "dz serve refuses a box folder (creds, .dropzone, notes.md), the boxes folder and the archive (they hold every box), anything above them, and your home folder, so a target can't download your creds or notes." \
  "Serve a subfolder: 'dz serve exploits' or 'dz serve ~/tools'."
_dz_def E607 "impacket-smbserver missing" \
  "'dz serve smb' uses impacket's SMB server, which isn't installed." \
  "'sudo apt install python3-impacket', or use HTTP: 'dz serve'."
_dz_def E608 "nothing to copy" \
  "The value you asked for is empty or unknown: no cred loaded for user/pass/hash, no domain, or a host that isn't in the box." \
  "'dz -cp' takes target, <host>, me, domain, targets, user, pass or hash."
_dz_def E609 "no nmap output found" \
  "dz -p without a file reads the newest .xml or .gnmap in the box's scans/ folder, and there is none." \
  "Scan with -oA or -oX into scans/: 'nmap -p- -oA scans/all \$TARGET_IP', or give the file: 'dz -p path/to/scan.xml'."
_dz_def E610 "can't read the nmap file" \
  "The file doesn't exist or isn't readable." \
  "Check the path, or let dz pick the newest in scans/ with 'dz -p'."
_dz_def W601 "scan has IPs outside the box" \
  "The nmap output has open ports on IPs that are not a host of the box, so dz skipped them." \
  "Add the host with 'dz -t <host> -ip <ip>' and run dz -p again; rows already there stay."
_dz_def W602 "note has no ports table" \
  "dz -p fills the first table under '## Ports' (or '### Poorten'), and the note has none." \
  "Add a table with a header row like '| Port | Service | Version | Notes |', see docs/notes.md."
_dz_def W603 "reptor not found" \
  "'sysreptor = yes' uploads evidence with the reptor CLI, which isn't installed. The evidence is saved locally anyway." \
  "'pip install reptor' and 'reptor conf', or set 'sysreptor = no'."

_dz_def W604 "serving your creds lists" \
  "The folder has users.txt, passwords.txt or hashes.txt, the lists 'dz -c --export' writes to loot/. Anyone who reaches the server can download them." \
  "Serve another folder ('dz serve exploits'), or move the lists out first. Ctrl-C stops the server."

# --- E7xx: setup, config, update
_dz_def E701 "dropzone is not a git clone" \
  "dz --update runs git pull in the dropzone folder, and that folder isn't a git clone (installed from a zip, a package or a copy)." \
  "Update it the way you installed it, or reinstall with git clone (see the README)."
_dz_def E702 "local changes in dropzone" \
  "You changed files inside the dropzone folder itself, and an update would mix with them." \
  "'git -C ~/dropzone stash' (or commit them), then dz --update again. Your own settings belong in ~/.config/dropzone/."
_dz_def E703 "git pull failed" \
  "git couldn't fast-forward: no network, GitHub unreachable, or your clone has its own commits." \
  "Read git's message above it. Own commits: 'git -C ~/dropzone status' and sort it out with git."
_dz_def W701 "config line skipped" \
  "A line in your config has an unknown setting, a value that isn't allowed, or isn't 'key = value'. dz skips that line and uses the default for it; the line number is in the message." \
  "'dz --config' to fix it; 'dz --config show' shows what's in use, config.example has every setting."
_dz_def W702 "vault mode without a vault" \
  "'notes = vault' needs 'vault = /path/to/your/vault'. Without it dz falls back to notes = folder." \
  "Set 'vault' with dz --config, or 'notes = folder'."

# --- E8xx: deadline
_dz_def E801 "not a deadline" \
  "--deadline takes a duration from now (10d, 48h, 9d12h), a date and time (2026-12-10T14:00 or '2026-12-10 14:00'), a date (= 23:59), or none." \
  "'dz --deadline 10d'."
_dz_def E802 "deadline in the past" \
  "The date or time you gave is already over." \
  "Check the date; a duration ('10d') always counts from now."

unfunction _dz_def

# dz --explain [code]: what an error or warning means and what to do. Without a code: the list.
_dz_explain() {
  emulate -L zsh
  local c=${(U)1}
  _dz_ui
  if [[ -z $c ]]; then
    for c in ${(ko)_dz_err_title}; do printf '%-6s %s\n' $c "$_dz_err_title[$c]"; done
    print -r -- "${_ud}dz --explain <code> for one, or docs/errors.md${_ur}"
    return 0
  fi
  [[ $c == <-> ]] && c=E$c
  (( $+_dz_err_title[$c] )) || { _dz_err E101 "no error code '$1' (dz --explain lists them)"; return 1 }
  _dz_rule; _dz_head $c "$_dz_err_title[$c]"
  _dz_row why "$_dz_err_why[$c]" 8
  _dz_row fix "$_dz_err_fix[$c]" 8
  _dz_rule
}
