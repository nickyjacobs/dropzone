# Security policy

## Reporting a vulnerability

Please don't open a public issue. Report it privately through [GitHub Security Advisories](https://github.com/nickyjacobs/dropzone/security/advisories/new) and include:

- what the problem is and what an attacker could do with it
- how to reproduce it (dropzone version from `dz --version`, zsh version, distro)

You get a reply within 7 days. Once a fix is released, the advisory is published and credited to you unless you prefer otherwise.

## Supported versions

Only the latest release gets fixes. Update with `dz --update`.

## Scope

dropzone runs in your own shell and handles files from targets (loot, dumps), so these are in scope:

- code execution through files dropzone reads (`.dropzone`, the config, creds, notes, templates)
- path traversal through box names or config values
- changes to `/etc/hosts` beyond the box's own tagged line
- secrets ending up somewhere they shouldn't (logs, notes, world-readable files)

Out of scope: the tools you run yourself from a dropzone shell, and plain-text creds in a note that you chose to store with `dz -c` (see [docs/commands.md](docs/commands.md#creds)).
