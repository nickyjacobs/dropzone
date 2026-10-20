# Errors

[README](../README.md) · [Guide](guide.md) · [Commands](commands.md) · [Notes](notes.md) · [Config](config.md) · **Errors** · [Testing](testing.md) · [Development](development.md)

When something goes wrong, dz says so in one line with a code:

```
dz [E201] no box loaded
• [W202] the route to 10.10.10.77 goes through eth0, not tun0
```

- **E** is an error: the command stopped and changed nothing more (exit status 1).
- **W** is a warning: dz tells you something and carries on.

`dz --explain E201` shows why it happens and what to do, right in your terminal; `dz --explain` lists every code. The same text is below.

<!-- Made by scripts/errors-doc.zsh from lib/errors.zsh. Change it there, not here. -->

## Overview

| Codes | Area |
|---|---|
| 1xx | Using dz |
| 2xx | Boxes |
| 3xx | Hosts in a box (dz -t) |
| 4xx | Notes, flags and evidence |
| 5xx | Creds |
| 6xx | Tools and ports |
| 7xx | Setup, config and update |
| 8xx | Deadline |

| Code | Meaning |
|---|---|
| [E101](#e101) | unknown option |
| [E102](#e102) | option needs a value |
| [E103](#e103) | more than one action |
| [E104](#e104) | no action given |
| [E105](#e105) | -ip / -h without a box action |
| [E106](#e106) | new box without an IP |
| [E107](#e107) | the menu needs a terminal |
| [E108](#e108) | removing needs a confirmation |
| [E201](#e201) | no box loaded |
| [E202](#e202) | no such box |
| [E203](#e203) | invalid box name |
| [E204](#e204) | not an IPv4 address |
| [E205](#e205) | invalid hostname |
| [E206](#e206) | can't write the box folder |
| [E207](#e207) | the loaded box is gone |
| [E208](#e208) | archive folder already exists |
| [E209](#e209) | can't restore: the folder is in the way |
| [W201](#w201) | VPN interface missing |
| [W202](#w202) | target not routed through the VPN |
| [W203](#w203) | hostname already in /etc/hosts |
| [W204](#w204) | no note template, no note |
| [W205](#w205) | template not found |
| [W206](#w206) | no note, status not set |
| [E301](#e301) | invalid host name |
| [E302](#e302) | no such host in the box |
| [E303](#e303) | new host without an IP |
| [E304](#e304) | the main host is changed with -ip / -h |
| [E305](#e305) | pivot not in the box |
| [E401](#e401) | notes are off |
| [E402](#e402) | the box has no note |
| [E403](#e403) | a flag has no spaces |
| [E404](#e404) | host name instead of a flag |
| [E405](#e405) | flag already stored |
| [E406](#e406) | flag slot already filled |
| [E407](#e407) | flag for an unknown host |
| [E408](#e408) | couldn't place the flag |
| [E409](#e409) | no screenshot tool |
| [E410](#e410) | no desktop for a screenshot |
| [E411](#e411) | nothing piped into dz -e |
| [E412](#e412) | no output to save |
| [W401](#w401) | unusual flag format |
| [W402](#w402) | terminal recording didn't start |
| [E501](#e501) | creds is off |
| [E502](#e502) | no such cred |
| [E503](#e503) | invalid host for --valid |
| [E504](#e504) | no creds to export |
| [E505](#e505) | secret prompt needs a terminal |
| [E506](#e506) | empty user or secret |
| [E507](#e507) | tab or newline in a cred |
| [W501](#w501) | host not in the box |
| [E601](#e601) | VPN interface down, no IP |
| [E602](#e602) | --via needs a pivot |
| [E603](#e603) | unknown pivot for dz serve |
| [E604](#e604) | SMB through a pivot |
| [E605](#e605) | no such folder to serve |
| [E606](#e606) | folder holds your box files |
| [E607](#e607) | impacket-smbserver missing |
| [E608](#e608) | nothing to copy |
| [E609](#e609) | no nmap output found |
| [E610](#e610) | can't read the nmap file |
| [W601](#w601) | scan has IPs outside the box |
| [W602](#w602) | note has no ports table |
| [W603](#w603) | reptor not found |
| [W604](#w604) | serving your creds lists |
| [E701](#e701) | dropzone is not a git clone |
| [E702](#e702) | local changes in dropzone |
| [E703](#e703) | git pull failed |
| [W701](#w701) | config line skipped |
| [W702](#w702) | vault mode without a vault |
| [E801](#e801) | not a deadline |
| [E802](#e802) | deadline in the past |

## 1xx · Using dz

<a id="e101"></a>
### E101 · unknown option

**Error.** dz doesn't know this option. Often a typo, or an option from a newer version than the one you have.

**What to do:** Check the spelling with `dz --help`. Options are case sensitive: -ip, not -IP.

<a id="e102"></a>
### E102 · option needs a value

**Error.** The option takes a value (a name, an IP, a file), but nothing followed it, or the next word starts with `-` and reads as another option.

**What to do:** Put the value right after the option: `dz -l jacops`, `dz -ip 10.10.10.5`. Quote values that contain spaces.

<a id="e103"></a>
### E103 · more than one action

**Error.** Every dz call does one thing: -n, -l, -v, -i, -x, -t, -p, -cp, -o, -d, -a, -f, -j, -s, -e, -g, -c or -r. Two of them in one call are refused, so nothing half happens.

**What to do:** Split it into two calls: `dz -l jacops` and then `dz -i`. Options like -ip, -h, --via and --template are not actions and can go along.

<a id="e104"></a>
### E104 · no action given

**Error.** The call has options but none of them says what to do, for example only `-y` or `--all`.

**What to do:** Add the action: `dz -v --all`, `dz -r jacops -y`. `dz` alone opens the menu.

<a id="e105"></a>
### E105 · -ip / -h without a box action

**Error.** -ip and -h change a box. Without -n or -l they change the loaded box; with another action (like -d) dz doesn't know what you mean.

**What to do:** Use `dz -ip <ip>` for the loaded box, `dz -l <name> -ip <ip>` for another one, or `dz -n <name> -ip <ip>` for a new one.

<a id="e106"></a>
### E106 · new box without an IP

**Error.** A box always has a target IP: it goes into $TARGET_IP, the note and /etc/hosts.

**What to do:** Give it: `dz -n jacops -ip 10.129.42.190`.

<a id="e107"></a>
### E107 · the menu needs a terminal

**Error.** The menu reads keys from a terminal. In a script, a pipe or `zsh -c` there is none.

**What to do:** Use the options instead of the menu (dz --help), or run dz in a normal terminal.

<a id="e108"></a>
### E108 · removing needs a confirmation

**Error.** dz -r asks before it removes a box, and there is no terminal to ask in (a script or a pipe).

**What to do:** Add -y to skip the question, and --note or --keep-note for the note: `dz -r jacops -y --keep-note`.

## 2xx · Boxes

<a id="e201"></a>
### E201 · no box loaded

**Error.** This command works on the loaded box, and no box is loaded in this terminal: you never loaded one, ran dz -x, or removed it.

**What to do:** Load one with `dz -l <name>` (dz -v lists them), or make one with `dz -n <name> -ip <ip>`.

<a id="e202"></a>
### E202 · no such box

**Error.** There is no box folder with that name under your boxes folder (~/boxes by default). It may be a typo, archived, removed, or in another `boxes` folder from your config.

**What to do:** See what's there with `dz -v --all`. An archived box comes back with `dz -l <name>`.

<a id="e203"></a>
### E203 · invalid box name

**Error.** Box names start with a letter or digit and only have letters, digits, `.`, `_` and `-`. That keeps names safe as folder names and in /etc/hosts tags.

**What to do:** Pick a name like `jacops`, `cpts-exam` or `ms01_lab`.

<a id="e204"></a>
### E204 · not an IPv4 address

**Error.** dz takes IPv4 addresses (four numbers from 0 to 255). A hostname, a CIDR range or an IPv6 address is not accepted as a target IP.

**What to do:** Give the IP: `-ip 10.129.42.190`. Hostnames go after -h.

<a id="e205"></a>
### E205 · invalid hostname

**Error.** A hostname for /etc/hosts starts with a letter or digit and has only letters, digits, `-` and `.`, like dc01.corp.local. Spaces, underscores, slashes or a scheme (http://) don't fit in a hosts line.

**What to do:** Fix the name, separate more names with commas: `-h dc01.corp.local,corp.local`.

<a id="e206"></a>
### E206 · can't write the box folder

**Error.** dz couldn't make the box folder or its .dropzone file: the boxes folder isn't writable, the disk is full, or the path in `boxes` points somewhere you can't write.

**What to do:** Check `dz --config show` for the boxes folder and that you own it: ls -ld ~/boxes.

<a id="e207"></a>
### E207 · the loaded box is gone

**Error.** This terminal still has a box loaded, but its folder is gone: removed or archived in another terminal.

**What to do:** Unload it with `dz -x`, or bring it back with `dz -l <name>` if it was archived.

<a id="e208"></a>
### E208 · archive folder already exists

**Error.** dz -a moves the box to _archive/<name>, but a folder with that name is already there, from an earlier box with the same name.

**What to do:** Look at the old one in ~/boxes/_archive/ and move or remove it, then archive again.

<a id="e209"></a>
### E209 · can't restore: the folder is in the way

**Error.** The box is archived, and dz -l wants to move it back to ~/boxes/<name>, but a folder with that name exists there and isn't a box.

**What to do:** Move that folder away, then run `dz -l <name>` again.

<a id="w201"></a>
### W201 · VPN interface missing

**Warning.** The interface from `iface` (tun0 by default) doesn't exist: your VPN isn't connected, or it uses another name. $ATTACKER_IP stays empty.

**What to do:** Connect your VPN. Another name (tun1, wg0)? Set `iface` with dz --config. `vpncheck = no` turns the check off.

<a id="w202"></a>
### W202 · target not routed through the VPN

**Warning.** Your Kali would reach the target over another interface than the VPN (or a pivot from `pivot`). Mostly a wrong IP, a VPN that isn't up, or a route from another network winning.

**What to do:** Check the IP and `ip route get <ip>`. A host behind a pivot? Make sure its interface matches `pivot` (default ligolo*).

<a id="w203"></a>
### W203 · hostname already in /etc/hosts

**Warning.** The hostname is also on a line in /etc/hosts that dz didn't write. Which IP wins depends on the order, so the name can point to an old target.

**What to do:** Remove or fix the old line in /etc/hosts (sudo nano /etc/hosts).

<a id="w204"></a>
### W204 · no note template, no note

**Warning.** dz couldn't find a note template, so the box has no note. Notes for flags, timeline and creds need one.

**What to do:** Check `template` with dz --config show, or put your template in ~/.config/dropzone/templates/box-note.md, then run the same dz -n again: it adds the note.

<a id="w205"></a>
### W205 · template not found

**Warning.** The template from `template` in your config or from --template doesn't exist where dz looked. A relative path is inside your vault (notes = vault) or ~/.config/dropzone.

**What to do:** Check the path, or the name: --template exam looks for exam.md, exam-note.md or Exam-note.md.

<a id="w206"></a>
### W206 · no note, status not set

**Warning.** The status (active/done) lives in the note's frontmatter, and this box has no note.

**What to do:** Make the note (W204), or ignore it: the box folder is fine.

## 3xx · Hosts in a box (dz -t)

<a id="e301"></a>
### E301 · invalid host name

**Error.** Host names in a box (dz -t) become variables like $DC01_IP, so they are lowercase letters, digits and `-`.

**What to do:** Use names like dc01, ms01, web-02.

<a id="e302"></a>
### E302 · no such host in the box

**Error.** The box has no host with that name. `dz -t` lists them; the main host is the box name itself.

**What to do:** Add it first: `dz -t <host> -ip <ip>`.

<a id="e303"></a>
### E303 · new host without an IP

**Error.** A host needs an IP to get its $<HOST>_IP and its hosts line.

**What to do:** `dz -t dc01 -ip 10.10.10.5`.

<a id="e304"></a>
### E304 · the main host is changed with -ip / -h

**Error.** The main host is the box itself. dz -t only switches back to it; its IP and hostnames change with dz -ip and dz -h, and as the entry point it has no pivot.

**What to do:** `dz -ip <ip>` or `dz -h <host,...>` for the main host.

<a id="e305"></a>
### E305 · pivot not in the box

**Error.** --via names the host this one sits behind, so that host must be in the box, and can't be the host itself.

**What to do:** Add the pivot first (`dz -t web01 -ip <its internal IP>`), then `dz -t ms01 --via web01`.

## 4xx · Notes, flags and evidence

<a id="e401"></a>
### E401 · notes are off

**Error.** `notes = off` in your config, so there is no note to open or write to.

**What to do:** Set `notes = folder` or `notes = vault` with dz --config.

<a id="e402"></a>
### E402 · the box has no note

**Error.** The note file isn't where dz expects it: it was never made (W204), was moved or renamed, or `notes`/`vault` changed in your config.

**What to do:** Check the path in the message. Run the same `dz -n <name> -ip <ip>` again to make a missing note.

<a id="e403"></a>
### E403 · a flag has no spaces

**Error.** Flags are one word (HTB flags are 32 hex characters). Spaces mean a copy-paste went wrong.

**What to do:** Copy the flag again: `dz -f 3f9a...e1`.

<a id="e404"></a>
### E404 · host name instead of a flag

**Error.** You gave a host name and no flag, so dz would store the host name as a flag.

**What to do:** Give both: `dz -f dc01 <flag>`.

<a id="e405"></a>
### E405 · flag already stored

**Error.** The same flag is already in the note. It's either a double paste or the same flag on two hosts.

**What to do:** `dz -f` lists the flags. Change the note by hand if something is wrong.

<a id="e406"></a>
### E406 · flag slot already filled

**Error.** A single box has one user and one root slot, and that slot (or both) has a flag. dz never overwrites a flag.

**What to do:** Look with `dz -f`. A wrong flag: fix it in the note. More flags? Add hosts (dz -t) and use `dz -f <host> <flag>`.

<a id="e407"></a>
### E407 · flag for an unknown host

**Error.** Flags per host go to a host of the box, and this one isn't there.

**What to do:** `dz -t` lists the hosts; add it with `dz -t <host> -ip <ip>`.

<a id="e408"></a>
### E408 · couldn't place the flag

**Error.** dz wrote the flag but couldn't find it back in the note: the Flags section has a layout dz doesn't know.

**What to do:** Use the layout from the bundled template (- **User flag:** lines) or the Obsidian callouts in examples/obsidian/, or a Flags section with a plain list.

<a id="e409"></a>
### E409 · no screenshot tool

**Error.** dz -s needs a screenshot tool, and none was found (or the one from `screenshot` isn't installed). On X11: xfce4-screenshooter, flameshot, gnome-screenshot, spectacle or ImageMagick's import. On Wayland: grim with slurp, spectacle, gnome-screenshot or flameshot.

**What to do:** Install one: `sudo apt install flameshot`, on Wayland `sudo apt install grim slurp`. Or set `screenshot = auto`.

<a id="e410"></a>
### E410 · no desktop for a screenshot

**Error.** There is no graphical session (DISPLAY / WAYLAND_DISPLAY), for example over SSH.

**What to do:** Take the screenshot in your desktop session (RDP, VNC, the VM window), or save output with `cmd | dz -e`.

<a id="e411"></a>
### E411 · nothing piped into dz -e

**Error.** dz -e saves what a command prints, so it needs a pipe. Typed alone, there's nothing to read.

**What to do:** `nxc smb $TARGET | dz -e smb signing`.

<a id="e412"></a>
### E412 · no output to save

**Error.** The command in front of dz -e printed nothing to stdout. Many tools print errors to stderr, which a pipe doesn't carry.

**What to do:** Add 2>&1 to the command: `cmd 2>&1 | dz -e caption`.

<a id="w401"></a>
### W401 · unusual flag format

**Warning.** HTB flags are 32 hex characters; this one isn't. It's stored anyway, because other platforms use other formats.

**What to do:** Nothing, if it's right. Otherwise fix it in the note.

<a id="w402"></a>
### W402 · terminal recording didn't start

**Warning.** `output = yes` records every new terminal with script(1), and that failed (no util-linux script, or no log folder). The terminal works without a recording.

**What to do:** Check `script --version` (needs util-linux) or set `output = no`.

## 5xx · Creds

<a id="e501"></a>
### E501 · creds is off

**Error.** Storing creds is opt-in, because they land in plain text in the box folder and the note.

**What to do:** Set `creds = yes` with dz --config.

<a id="e502"></a>
### E502 · no such cred

**Error.** There is no cred with that number in this box. Numbers are the order you stored them in.

**What to do:** `dz -c` lists the creds with their numbers.

<a id="e503"></a>
### E503 · invalid host for --valid

**Error.** --valid takes host names (like dc01) or IPs, separated by commas.

**What to do:** `dz -c 2 --valid dc01,ms01`.

<a id="e504"></a>
### E504 · no creds to export

**Error.** dz -c --export writes the creds of the box to loot/, and the box has none yet.

**What to do:** Store one first: `dz -c <user> <source>`.

<a id="e505"></a>
### E505 · secret prompt needs a terminal

**Error.** `dz -c <user>` asks for the secret without showing it, which needs a terminal. In a script or pipe there's none.

**What to do:** Use `dz -c <user>:<secret> [source]`, and start the line with a space to keep it out of your history.

<a id="e506"></a>
### E506 · empty user or secret

**Error.** A cred needs both: `user:secret`. One of them is empty, often from a `:` at the start or the end.

**What to do:** `dz -c alex:Welcome1 smb-share`.

<a id="e507"></a>
### E507 · tab or newline in a cred

**Error.** The creds file uses tabs between the fields, so a tab or newline inside a user, secret or source would break it.

**What to do:** Remove the tab or newline (it usually comes from a bad copy).

<a id="w501"></a>
### W501 · host not in the box

**Warning.** The cred is marked as valid on a host that isn't in the box (dz -t). It's stored anyway.

**What to do:** Add the host with `dz -t <host> -ip <ip>` if you want its IP and variables.

## 6xx · Tools and ports

<a id="e601"></a>
### E601 · VPN interface down, no IP

**Error.** This command needs your IP on the VPN (for download commands or to copy), and the `iface` interface has none.

**What to do:** Connect the VPN, or set `iface` to the right interface with dz --config.

<a id="e602"></a>
### E602 · --via needs a pivot

**Error.** dz serve --via takes the pivot: a host of the box or an IP.

**What to do:** `dz serve ~/tools --via web01` or `--via 172.16.5.15`.

<a id="e603"></a>
### E603 · unknown pivot for dz serve

**Error.** The pivot after --via isn't an IP and not a host of the loaded box.

**What to do:** Give its internal IP, or add it: `dz -t web01 -ip 172.16.5.15`.

<a id="e604"></a>
### E604 · SMB through a pivot

**Error.** Windows only talks SMB on port 445, and the pivot uses that port itself, so a ligolo listener can't forward it.

**What to do:** Use HTTP: `dz serve --via <pivot>`.

<a id="e605"></a>
### E605 · no such folder to serve

**Error.** The folder doesn't exist, as a path or as a subfolder of the loaded box.

**What to do:** Check the path; `dz serve exploits` serves the box's exploits/ folder.

<a id="e606"></a>
### E606 · folder holds your box files

**Error.** dz serve refuses a box folder (creds, .dropzone, notes.md), the boxes folder and the archive (they hold every box), anything above them, and your home folder, so a target can't download your creds or notes.

**What to do:** Serve a subfolder: `dz serve exploits` or `dz serve ~/tools`.

<a id="e607"></a>
### E607 · impacket-smbserver missing

**Error.** `dz serve smb` uses impacket's SMB server, which isn't installed.

**What to do:** `sudo apt install python3-impacket`, or use HTTP: `dz serve`.

<a id="e608"></a>
### E608 · nothing to copy

**Error.** The value you asked for is empty or unknown: no cred loaded for user/pass/hash, no domain, or a host that isn't in the box.

**What to do:** `dz -cp` takes target, <host>, me, domain, targets, user, pass or hash.

<a id="e609"></a>
### E609 · no nmap output found

**Error.** dz -p without a file reads the newest .xml or .gnmap in the box's scans/ folder, and there is none.

**What to do:** Scan with -oA or -oX into scans/: `nmap -p- -oA scans/all $TARGET_IP`, or give the file: `dz -p path/to/scan.xml`.

<a id="e610"></a>
### E610 · can't read the nmap file

**Error.** The file doesn't exist or isn't readable.

**What to do:** Check the path, or let dz pick the newest in scans/ with `dz -p`.

<a id="w601"></a>
### W601 · scan has IPs outside the box

**Warning.** The nmap output has open ports on IPs that are not a host of the box, so dz skipped them.

**What to do:** Add the host with `dz -t <host> -ip <ip>` and run dz -p again; rows already there stay.

<a id="w602"></a>
### W602 · note has no ports table

**Warning.** dz -p fills the first table under `## Ports` (or `### Poorten`), and the note has none.

**What to do:** Add a table with a header row like `| Port | Service | Version | Notes |`, see docs/notes.md.

<a id="w603"></a>
### W603 · reptor not found

**Warning.** `sysreptor = yes` uploads evidence with the reptor CLI, which isn't installed. The evidence is saved locally anyway.

**What to do:** `pip install reptor` and `reptor conf`, or set `sysreptor = no`.

<a id="w604"></a>
### W604 · serving your creds lists

**Warning.** The folder has users.txt, passwords.txt or hashes.txt, the lists `dz -c --export` writes to loot/. Anyone who reaches the server can download them.

**What to do:** Serve another folder (`dz serve exploits`), or move the lists out first. Ctrl-C stops the server.

## 7xx · Setup, config and update

<a id="e701"></a>
### E701 · dropzone is not a git clone

**Error.** dz --update runs git pull in the dropzone folder, and that folder isn't a git clone (installed from a zip, a package or a copy).

**What to do:** Update it the way you installed it, or reinstall with git clone (see the README).

<a id="e702"></a>
### E702 · local changes in dropzone

**Error.** You changed files inside the dropzone folder itself, and an update would mix with them.

**What to do:** `git -C ~/dropzone stash` (or commit them), then dz --update again. Your own settings belong in ~/.config/dropzone/.

<a id="e703"></a>
### E703 · git pull failed

**Error.** git couldn't fast-forward: no network, GitHub unreachable, or your clone has its own commits.

**What to do:** Read git's message above it. Own commits: `git -C ~/dropzone status` and sort it out with git.

<a id="w701"></a>
### W701 · config line skipped

**Warning.** A line in your config has an unknown setting, a value that isn't allowed, or isn't `key = value`. dz skips that line and uses the default for it; the line number is in the message.

**What to do:** `dz --config` to fix it; `dz --config show` shows what's in use, config.example has every setting.

<a id="w702"></a>
### W702 · vault mode without a vault

**Warning.** `notes = vault` needs `vault = /path/to/your/vault`. Without it dz falls back to notes = folder.

**What to do:** Set `vault` with dz --config, or `notes = folder`.

## 8xx · Deadline

<a id="e801"></a>
### E801 · not a deadline

**Error.** --deadline takes a duration from now (10d, 48h, 9d12h), a date and time (2026-12-10T14:00 or `2026-12-10 14:00`), a date (= 23:59), or none.

**What to do:** `dz --deadline 10d`.

<a id="e802"></a>
### E802 · deadline in the past

**Error.** The date or time you gave is already over.

**What to do:** Check the date; a duration (`10d`) always counts from now.
