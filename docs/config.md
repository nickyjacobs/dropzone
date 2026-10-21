# Config

[README](../README.md) · [Guide](guide.md) · [Commands](commands.md) · [Notes](notes.md) · **Config** · [Errors](errors.md) · [Testing](testing.md) · [Development](development.md)

dropzone reads one file: `~/.config/dropzone/config`. `install.sh` creates it from [config.example](../config.example).

```bash
dz --config         # open in $EDITOR (nano if unset), applies right after saving
dz --config show    # the values in use now, and whether each comes from your config or the default
dz --config check   # settings you don't have yet, after an update
```

## Format

```ini
[box]

# Subfolders in every box, separated by spaces
folders = scans loot exploits evidence
```

- One `key = value` per line. Spaces around `=` don't matter.
- `#` starts a comment, also after a value.
- `[paths]`, `[box]`, `[log]`, `[notes]`, `[creds]`, `[sysreptor]` and `[menu]` are only there to keep it readable. A key works in any section.
- Remove a line, or leave the value empty, to get the default back.
- `~` at the start of a path is your home folder.
- `yes` / `no` settings also take `true` / `false` and `on` / `off`.

## Settings

### [paths]

| Key | Default | Does |
|---|---|---|
| `boxes` | `~/boxes` | where box folders are created, an absolute path |

### [box]

| Key | Default | Does |
|---|---|---|
| `folders` | `scans loot exploits evidence logs` | subfolders in every new box |
| `iface` | `tun0` | interface for `$ATTACKER_IP` and `$INTERFACE`, shown in the menu |
| `autoload` | `yes` | load the last box in new terminals |
| `pivot` | `ligolo*` | interfaces of a pivot tunnel, patterns separated by spaces, or `none`: a route through one of them is fine for the VPN check |
| `ping` | `yes` | ping the target once after `-n` or `-ip` (info only) |
| `vpncheck` | `yes` | warn when the VPN interface is down or the route to the target doesn't go through it; never blocks |
| `prompt` | `yes` | show `[box ip]-` in your prompt, see [Prompt](#prompt) |

### [log]

| Key | Default | Does |
|---|---|---|
| `commands` | `yes` | every command with date, time and folder to `logs/commands.log` |
| `output` | `no` | full terminal output with `script(1)` to `logs/<date>_<time>.log` |

- `commands`: start a command with a space to keep it out of the log, handy for passwords.
- `output`: starts in every **new** terminal while a box is loaded. `exit` ends the recording and closes the terminal. If `script` can't start, the terminal carries on without a recording. `dz -i` shows the file. A `.timing` file sits next to it, so `scriptreplay -T <file>.timing <file>.log` plays it back.

### [notes]

| Key | Default | Does |
|---|---|---|
| `notes` | `folder` | where the box note goes: `folder` (`~/boxes/<box>/notes.md`), `vault` (your Obsidian vault) or `off` |
| `template` | empty | template for new notes; empty = `~/.config/dropzone/templates/box-note.md`, see [notes.md](notes.md#templates) |
| `vault` | empty | your vault, for `notes = vault` |
| `vault_folder` | `Boxes` | note folder inside the vault |
| `attachments` | `Boxes/attachments` | folder inside the vault for screenshot copies, one subfolder per box |
| `timeline` | `Timeline` | heading of the timeline section (`## Timeline`), filled by `dz -j`, `-s`, `-e`, `-f` and others |
| `add_sections` | `yes` | add a missing Timeline, Flags, To do or Findings section to the note; `no` leaves your layout alone and names the missing heading |
| `flag_goal` | `0` | flags to find in a box with more hosts; `dz -f` counts against it (`14` for the CPTS exam), `0` = no count |
| `screenshot` | `auto` | tool for `dz -s`: `auto` (first found, Wayland tools first on Wayland), `xfce4-screenshooter`, `flameshot`, `gnome-screenshot`, `spectacle`, `grim` (with `slurp`) or `import` |

Without a `notes` line, dropzone uses `vault` when a vault is set and `folder` otherwise. All about notes, templates and Obsidian: **[notes.md](notes.md)**.

### [creds]

| Key | Default | Does |
|---|---|---|
| `creds` | `no` | store credentials per box with `dz -c`, see [commands.md](commands.md#creds) |

### [sysreptor]

| Key | Default | Does |
|---|---|---|
| `sysreptor` | `no` | also upload `dz -s` screenshots and `dz -e` output to your SysReptor project's notes, see [commands.md](commands.md#sysreptor) |

### [menu]

| Key | Default | Does |
|---|---|---|
| `art` | `random` | banner art `1` to `10`, or `random` |
| `animate` | `yes` | decrypt intro and green wave; `no` shows the banner straight away |

`DZ_ART=7 dz` picks an art for a single run, whatever the config says.

## Prompt

`_dz_prompt` prints the loaded box as a prompt segment, `[jacops 10.129.42.190]-`, and nothing when no box is loaded. Another host as the target (`dz -t`) shows as `[corp dc01 10.10.10.5]-`, a deadline (`dz --deadline`) as `[cpts 10.129.5.10 5d22h]-`. Put it in your `PROMPT` (needs `setopt prompt_subst`, which Kali's `.zshrc` already sets):

```zsh
PROMPT='┌──(%n㉿%m)-$(_dz_prompt 2>/dev/null)[%~]
└─$ '
```

`2>/dev/null` keeps the prompt clean if dropzone is ever not loaded. `prompt = no` hides the segment without touching your `.zshrc`.

Colour in `dz --help` and `dz --config show` is off when the output is piped or `NO_COLOR` is set.

## Examples

Work over WireGuard instead of the HTB VPN:

```ini
iface = wg0
```

Smaller box folders, and no ping:

```ini
folders = loot evidence
ping = no
```

Always the same banner, no animation:

```ini
art = 1
animate = no
```

## Mistakes

The file is read, never run as code. A line it doesn't understand is skipped with a message, and the rest still loads:

```
• [W701] config line 8: autoload must be yes or no, not 'maybe' (line skipped)
• [W701] config line 9: unknown setting 'colour' (line skipped)
```

`dz --explain W701` says more; all codes are in [errors.md](errors.md).

Check what is in use with `dz --config show`.

## After an update

`dz --update` never changes your config. A new setting simply works with its default. `dz --config check` lists the settings from the new `config.example` that aren't in your file yet, with their comment, and old key names that still work under a new name.

## Files dropzone keeps

| Path | Holds |
|---|---|
| `~/.config/dropzone/config` | your config |
| `~/.config/dropzone/templates/box-note.md` | your note template, `install.sh` copies it once |
| `~/.config/dropzone/current` | last loaded box |
| `~/.cache/dz-art-last` | last banner art, so the next start shows another one |
| `~/boxes/<box>/.dropzone` | name, IP, hostnames and extra hosts of the box; read, never run |
| `~/boxes/<box>/.via`, `.deadline`, `.finding`, `.creds-current` | pivots, the deadline, the active finding and the active cred |
| `~/boxes/<box>/creds` | creds, with `creds = yes` (chmod 600) |
| `~/boxes/<box>/loot/users.txt`, `passwords.txt`, `hashes.txt` | from `dz -c --export` |
| `~/boxes/<box>/evidence/` | screenshots from `dz -s`, output from `dz -e` |
| `~/boxes/<box>/notes.md` | the box note, with `notes = folder` |
| `<vault>/Boxes/attachments/<box>/` | copies of screenshots, with `notes = vault` |
| `~/boxes/<box>/logs/` | `commands.log`, recordings when `output = yes`, `sysreptor.log` |
| `/etc/hosts.dz.bak` | `/etc/hosts` as it was before dropzone last changed it |
