# Changelog

All notable changes to dropzone. Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/nickyjacobs/dropzone/compare/v1.1.5...HEAD
[1.1.5]: https://github.com/nickyjacobs/dropzone/compare/v1.1.0...v1.1.5
[1.1.0]: https://github.com/nickyjacobs/dropzone/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nickyjacobs/dropzone/releases/tag/v1.0.0
