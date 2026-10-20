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

## Why dropzone

I built dropzone during my CPTS prep. Every new box started the same way: make the folders, copy a note template, add the hosts entry, export the IP, and later paste flags, creds and screenshots into the note by hand. Ten minutes of setup before the real work starts, and easy to get wrong when you're tired.

So dropzone is the place I start. Today that's HTB boxes and the CPTS exam, next it's CTFs, and later real pentests: one command sets up the drop zone, and everything you find during the engagement lands in it.

## Feedback wanted

dropzone is young and grew out of one person's workflow, so it probably misses things that are obvious in yours. If you try it, I'd like to hear:

- what was confusing or broke on your setup
- what you still do by hand for every box
- what you'd need for CTFs, Pro Labs or real engagements

Post it in [Discussions](https://github.com/nickyjacobs/dropzone/discussions), open an [issue](https://github.com/nickyjacobs/dropzone/issues/new/choose) or send a pull request. "I tried it and X annoyed me" is useful feedback too.

## Features

- **Box in one command**: `dz -n jacops -ip 10.129.42.190 -h jacops.htb` makes the folder, the note, the `/etc/hosts` line and loads `$TARGET_IP`, `$DOMAIN` and `$ATTACKER_IP` in your shell.
- **Your note writes itself**: a timeline with `dz -j`, screenshots with `dz -s`, command output with `cmd | dz -e`, flags with `dz -f`, creds with `dz -c`, and a new IP changes everywhere in the note.
- **Notes your way**: plain Markdown in the box folder, or in your Obsidian vault. `dz -g` searches the notes of every box.
- **More hosts per box** for AD sets and pivots: `dz -t dc01 -ip ...` gives `$DC01_IP`, `$TARGETS` and a hosts line, `dz -t dc01` makes it the target.
- **Exam-ready**: `--template exam`, flags per host with a count, hosts behind a pivot (`--via`), a `--deadline` in your prompt, creds per host with an export for spraying, and evidence to SysReptor if you want.
- **Your nmap output in the note**: `dz -p` fills the ports table from your own scan; dropzone never scans.
- **Less typing**: `dz serve` prints download commands with your IP, `dz -cp` copies an IP or a cred, and a warning appears when your VPN is down.
- **Every terminal knows the box**: new shells load the last box, your prompt shows it, and each command is logged per box.
- **Interactive menu** with `dz` (target and note submenus), short options for everything else, tab completion.
- **Clear errors**: every error has a code, like `dz [E201] no box loaded`, and `dz --explain E201` tells you why and what to do.
- **Safe**: files are read, never run, `/etc/hosts` is backed up, removed boxes go to the trash.

## Quick start

Needs zsh 5.8+, perl and `ip` (iproute2), all on Kali by default. A few commands use optional tools, and tell you when one is missing: `xclip`, `xsel` or `wl-copy` for `dz -cp`, a screenshot tool for `dz -s` (`xfce4-screenshooter`, `flameshot`, `gnome-screenshot`, `spectacle` or ImageMagick; on Wayland `grim` + `slurp`), `python3` and `impacket-smbserver` for `dz serve`, `sudo` for `/etc/hosts`, `reptor` for the opt-in SysReptor upload.

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
nxc smb $TARGETS 2>&1 | dz -e smb hosts  # command output as evidence in the note
dz -f 3f9a...e1                          # flag into the note
dz -g kerberoast                         # search the notes of every box
dz -v                                    # all boxes with status
dz -a jacops                             # done: archive it
dz --help                                # everything else
```

An exam with one entry point and hosts behind a pivot:

```bash
dz -n cpts -ip 10.129.5.10 --template exam --deadline 10d
dz -t web01 -ip 172.16.5.15                    # the pivot
dz -t ms01 -ip 172.16.5.10 --via web01         # a host behind it
dz serve ~/tools --via web01                   # ligolo-ng listener + download commands
dz -f ms01 3f9a...e1                           # flag 3/14
```

Every option: **[docs/commands.md](docs/commands.md)**. What you really need to know, and the gotchas: **[docs/guide.md](docs/guide.md)**.

## When something goes wrong

dz says what went wrong in one line with a code:

```
dz [E201] no box loaded
• [W202] the route to 10.10.10.77 goes through eth0, not tun0
```

An **E**rror stops the command, a **W**arning only tells you. `dz --explain E201` shows why it happens and how to fix it; **[docs/errors.md](docs/errors.md)** lists every code.

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
| [Guide](docs/guide.md) | how dz behaves, what trips people up, an exam run-through |
| [Commands](docs/commands.md) | every option, the menu, the variables |
| [Notes](docs/notes.md) | note locations, templates (also the exam template), Obsidian |
| [Config](docs/config.md) | every setting with its default |
| [Errors](docs/errors.md) | every error and warning code: why it happens, what to do |
| [Testing](docs/testing.md) | what the tests cover, and what still needs a check by hand |
| [Development](docs/development.md) | layout, tests, error codes, conventions, releases |
| [Changelog](CHANGELOG.md) | what changed per version |

## Exam use

OSCP bans tools that exploit or scan on their own. dropzone only does admin: folders, notes, screenshots, variables and hosts entries. It never scans, exploits or connects to a target; the only packet it sends is one ping after `-n` or `-ip` (`ping = no` turns it off). `dz serve` starts a file server for you and prints the commands, you run them. The SysReptor upload is off by default; check your exam's rules before you turn it on.

## Contributing

Ideas and questions go to [Discussions](https://github.com/nickyjacobs/dropzone/discussions), bugs and pull requests are welcome too, see [CONTRIBUTING.md](CONTRIBUTING.md). Security problems: [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © Nicky Jacobs
