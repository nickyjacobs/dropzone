<p align="center">
  <img src="assets/banner.png" alt="dropzone" width="100%">
</p>

<p align="center">
  <a href="https://github.com/nickyjacobs/dropzone/releases/latest"><img src="https://img.shields.io/github/v/release/nickyjacobs/dropzone?color=00c853&label=release" alt="Latest release"></a>
  <a href="https://github.com/nickyjacobs/dropzone/actions/workflows/ci.yml"><img src="https://github.com/nickyjacobs/dropzone/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-yellow" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/shell-zsh-89e051?logo=gnubash&logoColor=white" alt="Shell: zsh">
  <img src="https://img.shields.io/badge/platform-Kali_Linux-268bee?logo=kalilinux&logoColor=white" alt="Platform: Kali Linux">
  <img src="https://img.shields.io/badge/OSCP-exam--safe-2ea44f" alt="OSCP: exam-safe">
</p>

<p align="center">
  <b>One command per box: work folder, note, target variables and hosts entry, ready before you start.</b><br>
  Built for HTB, CPTS and OSCP on Kali.
</p>

<p align="center">
  <img src="assets/demo.gif" alt="dropzone demo" width="85%">
</p>

## Features

- **Box in one command**: `dz -n jacops -ip 10.129.42.190 -h jacops.htb` makes the folder, the note, the `/etc/hosts` line and loads `$TARGET_IP`, `$DOMAIN` and `$ATTACKER_IP` in your shell.
- **Your note writes itself**: a timeline with `dz -j`, screenshots with `dz -s`, flags with `dz -f`, creds with `dz -c`, and a new IP changes everywhere in the note.
- **Notes your way**: plain Markdown in the box folder, or in your Obsidian vault.
- **More hosts per box** for AD sets and pivots: `dz -t dc01 -ip ...` gives `$DC01_IP`, `$TARGETS` and a hosts line, `dz -t dc01` makes it the target.
- **Your nmap output in the note**: `dz -p` fills the ports table from your own scan; dropzone never scans.
- **Less typing**: `dz serve` prints download commands with your IP, `dz -cp` copies an IP or a cred, and a warning appears when your VPN is down.
- **Every terminal knows the box**: new shells load the last box, your prompt shows it, and each command is logged per box.
- **Interactive menu** with `dz`, short options for everything else, tab completion.
- **Safe**: files are read, never run, `/etc/hosts` is backed up, removed boxes go to the trash.

## Quick start

Needs zsh 5.8+ and perl (both on Kali by default).

```bash
git clone https://github.com/nickyjacobs/dropzone.git ~/dropzone
~/dropzone/install.sh
exec zsh
```

Then:

```bash
dz -n jacops -ip 10.129.42.190 -h jacops.htb
```

## Usage

```bash
dz                                       # interactive menu
dz -n jacops -ip 10.129.42.190           # new box
dz -ip 10.129.42.201                     # box was reset: new IP everywhere
dz -h dc01.jacops.htb,jacops.htb         # hostnames for an AD box
dz -t dc01 -ip 10.129.42.191             # another host in the box: $DC01_IP
dz -p                                    # open ports from your nmap output into the note
dz serve ~/tools 8000                    # HTTP server + download commands with your IP
dz -cp dc01                              # copy a host's IP to the clipboard
dz -j found an NFS share with backups    # line in the note's timeline
dz -s showmount output                   # screenshot, embedded in the note
dz -f 3f9a...e1                          # flag into the note
dz -v                                    # all boxes with status
dz -a jacops                             # done: archive it
dz --help                                # everything else
```

Every option: **[docs/commands.md](docs/commands.md)**.

## Notes

Every box gets a Markdown note from a template. By default it's `~/boxes/<box>/notes.md`; with `notes = vault` it goes into your Obsidian vault instead.

| Setting | `notes = folder` (default) | `notes = vault` |
|---|---|---|
| Note | `~/boxes/<box>/notes.md` | `<vault>/Boxes/<box>.md` |
| Template | `~/.config/dropzone/templates/box-note.md` | any file in your vault |
| `dz -o` opens it in | your editor | Obsidian |

How templates work, what dropzone writes where, and an Obsidian setup with callouts and a Dataview dashboard: **[docs/notes.md](docs/notes.md)** · [examples/obsidian](examples/obsidian/).

## Configuration

One readable file, `~/.config/dropzone/config`:

```ini
[box]
folders = scans loot exploits evidence logs
iface = tun0

[notes]
notes = folder
timeline = Timeline
```

`dz --config` opens it, `dz --config show` prints what is in use. Every setting: **[docs/config.md](docs/config.md)**.

## Updating

```bash
dz --update
```

Pulls the new version and shows what changed. Your config, templates, boxes and notes live outside the dropzone folder, so an update never touches them. `dz --config check` lists new settings you might want.

## Documentation

| Page | What it covers |
|---|---|
| [Commands](docs/commands.md) | every option, the menu, the variables |
| [Notes](docs/notes.md) | note locations, templates, Obsidian |
| [Config](docs/config.md) | every setting with its default |
| [Development](docs/development.md) | layout, tests, conventions, releases |
| [Changelog](CHANGELOG.md) | what changed per version |

## Exam use

OSCP bans tools that exploit or scan on their own. dropzone only does admin: folders, notes, screenshots, variables and hosts entries. It never touches the target.

## Contributing

Issues and pull requests are welcome, see [CONTRIBUTING.md](CONTRIBUTING.md). Security problems: [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © Nicky Jacobs
