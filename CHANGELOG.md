# Changelog

All notable changes to dropzone. Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **To-dos** (`dz --todo <text>`): your own checklist in the note's `## To do` section, tagged with the active host in a box with more hosts. `dz --todo` lists the open ones, `--todo --all` the done ones too, `dz --todo done <nr>` ticks one off (ticking it in Obsidian works as well). dz never suggests to-dos itself.
- **Findings** (`dz --finding <title>`): a `### F1 · <title>` heading under `## Findings` with its host and status. While a finding is active, `dz -s` and `dz -e` put their evidence under it and the timeline points to it. A Findings table (the exam template) gets a row with the evidence count and status. `dz --finding` lists them, `--finding <nr>` switches, `--finding off` stops, `--finding done [nr]` closes one.
- **What's next in `dz -i`**: a *Next* block with the open to-dos, the active finding and the last timeline lines.
- **One host** (`dz -i <host>`): its IP, hostnames, pivot, flags, to-dos, findings and the creds that work there (user and number, never the secret).
- `add_sections = no` in the config: dz never adds a Timeline, Flags, To do or Findings section to your note, it tells you which heading is missing (`E413`, `W403`).
- Menu: *Notes ›* has *To do* and *Finding*.
- The templates (`box-note.md`, `exam-note.md`, the Obsidian example) have a `## To do` section; the box templates also `## Findings`.

### Fixed
- `dz -c 'corp\user'` printed the user without the backslash (`corpuser`); the stored cred was right.
- `dz -f root <flag>` on a note with a `## Flags` section but no user/root lines added a second Flags section.

## [1.3.1] - 2026-10-20

### Fixed
- `dz -i` on a box with a deadline and more hosts showed a timestamp instead of the main host's IP.
- `dz -i` showed the note's full path instead of `~/...`.

### Changed
- Docs: the guide covers `dz -g`, removing an archived box and what `dz serve` refuses.
- Docs: new GIFs of the 10 banner arts and of a box with more hosts (`docs/commands.md`, `docs/guide.md`); the demo and menu GIFs show hosts, `dz -e` and the submenus, without VPN warnings.

## [1.3.0] - 2026-10-20

### Added
- **Menu submenus**: *Target ›* (Change IP, Switch host, Add host, Deadline) and *Notes ›* (Open note, Timeline entry, Add flag, Creds). The main menu keeps 8 items; *Creds* asks for the secret without showing it.
- The menu's status line shows the active host and the time left with a deadline.
- **Search the notes** (`dz -g <term> [--all]`): every line with the term from the notes of all boxes, per box with line numbers; `--all` includes the archive.
- **Wayland screenshots** for `dz -s`: `grim` with `slurp` and `spectacle`, tried first on Wayland; `spectacle` also on X11. `screenshot = grim` / `spectacle` in the config (#5).
- New banner arts: next to the classic logo, nine arts with the word DROPZONE in their own letters and a scene of what dz does (a parachute, the crate with the box folders, the plane, the landing marker, a pivot drop, the terminal, the note, the flag and the exam clock).

### Changed
- Docs: README explains why dropzone exists and asks for feedback; ideas and questions go to Discussions.
- `dz -r` also removes an archived box.

### Fixed
- `art = <n>` in the config was checked against a fixed 10 instead of the real number of arts, because the arts loaded after the config.
- `dz -n a -ip <ip> -l b` loaded `b` instead of refusing two actions.

### Security
- `dz serve` refused a box folder, but not the boxes folder itself, the archive or a folder above them, which hold every box and its creds. Those are refused now, and serving the lists from `dz -c --export` gives a warning (`W604`).

## [1.2.0] - 2026-10-18

### Added
- **Command output as evidence** (`<cmd> | dz -e [caption]`): the output to `evidence/`, colours stripped, with the command from `commands.log`, and the first 30 lines as a code block in the timeline.
- **Exam template** (`dz -n ... --template exam`): Scope, Hosts with a *Via* column, Ports with a Host column, Credentials, Findings, Host notes, flags per host. `--template <name>` also finds your own templates.
- **Hosts behind a pivot** (`dz -t <host> --via <pivot>`): shown in `dz -t` and `dz -i`, the *Via* column of the note, `--via none` clears it.
- **Deadline** (`dz --deadline 10d`, a date, `none`): `dz -i` shows `day 4/10 · 5d22h left`, the prompt shows what's left.
- **Creds export** (`dz -c --export`): users, passwords and NT hashes to `loot/` for your own spraying.
- **Key and ticket creds**: a private key file sets `$SSH_KEY`, a `.ccache` sets `$KRB5CCNAME`.
- **SysReptor** (`sysreptor = yes`, opt-in): `dz -s` and `dz -e` also upload to your project's notes with reptor, in the background.
- `dz -t` puts a `### <host>` heading under `## Host notes` when the note has that section.
- **Error codes**: every error and warning has a code, `dz [E201] no box loaded` / `• [W202] ...`. `dz --explain <code>` says why it happens and what to do, `dz --explain` lists them all.
- Docs: [guide.md](docs/guide.md) (how dz behaves, what trips people up, an exam run-through), [errors.md](docs/errors.md) (every code, made from `lib/errors.zsh`) and [testing.md](docs/testing.md) (what the tests cover, what still needs a check by hand).

### Changed
- Error and warning messages start with their code; config mistakes read `• [W701] config line 8: ... (line skipped)`.
- A note without user/root flag slots (like the exam template) keeps flags per host, also with one host.

### Fixed
- `scripts/release.sh` works on macOS (perl instead of BSD sed).

## [1.1.5] - 2026-10-18

### Added
- **Flags per host** (`dz -f <host> <flag>`): on a box with more hosts every flag is a line in `## Flags` with the host and the time, `dz -f <flag>` uses the active host. `dz -f` lists them with a count; `flag_goal = 14` in the config shows `9/14 flags`.
- **Where a cred works** (`dz -c [nr] --valid <host,...>`): `dz -c` shows the hosts and the *Valid on* column of the note is filled. Also while storing a cred.
- **Domain users**: a cred like `corp\svc_sql` or `jdoe@corp.local` sets `$CRED_DOMAIN`, and `$TARGET_USER` without the domain.
- **`dz serve --via <host|ip>`** for hosts behind a pivot: prints the ligolo-ng `listener_add` line and download commands with the pivot's IP. Port 8000 unless you give one.
- `pivot` setting (default `ligolo*`): interfaces of a pivot tunnel.
- Docs: sections for `dz --update` and the VPN check in `docs/commands.md`.

### Fixed
- The VPN check warned for every host behind a ligolo-ng pivot, because its route goes through `ligolo` instead of `tun0`. A route through a `pivot` interface is fine now.
- A root flag no longer marks a box with more hosts done: one host's root isn't the end of an exam or AD set.

## [1.1.0] - 2026-10-14

### Added
- **Ports from nmap** (`dz -p [file]`): open ports from your own `-oX` / `-oA` / `-oG` output into the note's ports table, matched to the hosts of the box, without touching rows you already have. dropzone never scans.
- **`dz serve [smb] [dir] [port]`**: an HTTP server or SMB share, with download commands that have your IP in them. It listens on your VPN IP only, and refuses a folder with box files in it.
- **`dz -cp [what]`**: copy the target IP, a host, your IP, a cred or all IPs to the clipboard.
- **VPN check** (`vpncheck = yes`): a warning when the VPN interface is down or the route to the target doesn't go through it.
- **More hosts per box** (`dz -t`): `dz -t dc01 -ip <ip> [-h <host,...>]` adds a host with `$DC01_IP`, a tagged `/etc/hosts` line, a row in the note's Hosts table and a timeline line. `dz -t dc01` makes it the target (`$TARGET_IP`, `$TARGET`, `$DOMAIN` and the prompt follow), `dz -t` lists them, `--drop` removes one. `$TARGETS` has every IP of the box.
- `dz -i` and `dz -v` show the extra hosts.

### Changed
- `dz --help`, `dz -i` and `dz --config show/check` in blocks: a rule, `[+] Section`, indented rows. The help is grouped into Boxes, Target, Notes and Setup.
- Tables in the README and docs have a header row; every doc page has the same navigation line.
- The prompt shows the active host when it isn't the main one: `[corp dc01 10.10.10.5]-`.
- The demo GIF starts without a loaded box; a second GIF shows the menu in `docs/commands.md`.
- `scripts/release.sh` prepares a release on `develop`; `scripts/release.sh --tag` tags it on `main` after the merge, because `main` only takes pull requests.
- The bundled template has a `## Hosts` table with Host, IP and Hostnames columns.
- Archiving a box removes all its `/etc/hosts` lines; restoring it with `dz -l` puts them back.

### Fixed
- The menu's *Change IP* always changes the main host.
- The link check no longer fails on the CHANGELOG's compare links, which point to a tag that only exists after the release.
- One test used the real `/etc/hosts` (it asked for sudo and failed); every test now has its own hosts file, and runs with the VPN check off.

## [1.0.0] - 2026-10-14

First public release.

### Added
- **One command, `dz`**: an interactive menu without arguments, short options for every action, `--help` and tab completion.
- **New box** (`dz -n <name> -ip <ip> -h <host,...>`): work folder with subfolders, a note from a template, a tagged `/etc/hosts` line (backed up first) and one ping.
- **Target variables** in every shell: `$BOX`, `$TARGET_IP`, `$TARGET`, `$DOMAIN`, `$ATTACKER_IP` (refreshed after a VPN reconnect) and `$INTERFACE`, named like The Hacker Recipes and Exegol. New terminals load the last box.
- **IP and hostname changes** (`dz -ip`, `dz -h`) everywhere: box file, note (exact match) and `/etc/hosts`.
- **Notes**: plain Markdown in the box folder (default), in an Obsidian vault, or off. A bundled template, your own copy in `~/.config/dropzone/templates/`, placeholders `{{name}}`, `{{ip}}`, `{{hosts}}`, `{{date}}` and `$TARGET_IP`.
- **Timeline, screenshots and flags in the note**: `dz -j`, `dz -s` (region screenshot to `evidence/`, embedded in the note) and `dz -f` (root flag marks the box done).
- **Status and archive**: `dz -d`, `dz -a`, `dz -v [--all]`, `dz -o` to open the note.
- **Creds per box**, opt-in: `dz -c`, with `$TARGET_USER` plus `$PASSWORD` or `$NT_HASH` and a hidden secret prompt.
- **Logging**: every command per box in `logs/commands.log`, optional full terminal recording with `script(1)`.
- **Prompt segment** with the loaded box.
- **Readable config** (`key = value`), `dz --config`, `dz --config show`, `dz --config check`.
- **Updates** with `dz --update`; config, templates, boxes and notes live outside the repo and are never touched.
- **Safety**: files are parsed, never sourced; box names are validated everywhere; removed boxes go to the trash.
- `examples/obsidian/`: a callout template, a Dataview dashboard and setup notes.
- Tests, CI on Ubuntu and Kali, secret scan, link check, releases from this changelog.

[Unreleased]: https://github.com/nickyjacobs/dropzone/compare/v1.3.1...HEAD
[1.3.1]: https://github.com/nickyjacobs/dropzone/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/nickyjacobs/dropzone/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/nickyjacobs/dropzone/compare/v1.1.5...v1.2.0
[1.1.5]: https://github.com/nickyjacobs/dropzone/compare/v1.1.0...v1.1.5
[1.1.0]: https://github.com/nickyjacobs/dropzone/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nickyjacobs/dropzone/releases/tag/v1.0.0
