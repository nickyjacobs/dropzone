# Notes

[README](../README.md) · [Commands](commands.md) · **Notes** · [Config](config.md) · [Development](development.md)

Every box gets a note: one Markdown file for what you find, your timeline, screenshots, creds and flags. dropzone creates it from a template with `dz -n` and keeps writing into it with `dz -j`, `dz -s`, `dz -f` and `dz -c`.

- [Where the note goes](#where-the-note-goes)
- [Templates](#templates)
- [What dropzone writes into the note](#what-dropzone-writes-into-the-note)
- [Obsidian](#obsidian)
- [Updates](#updates)

## Where the note goes

Set with `notes` in the config (`dz --config`):

| `notes =` | Note | Screenshots in the note | `dz -o` opens it in |
|---|---|---|---|
| `folder` (default) | `~/boxes/<box>/notes.md` | `![caption](evidence/<file>.png)` | `$VISUAL` / `$EDITOR`, or the desktop's default app |
| `vault` | `<vault>/<vault_folder>/<box>.md` | a copy in `<vault>/<attachments>/<box>/`, embedded as `![[...]]` | Obsidian |
| `off` | no note | only saved in `evidence/` | – |

`folder` needs nothing: plain Markdown that reads fine in any editor, renders on GitHub and works in Obsidian when you open `~/boxes` as a vault. Archived boxes take their note along to `~/boxes/_archive/<box>/`.

## Templates

A new note is a copy of the template with these placeholders filled in:

| Placeholder | Becomes |
|---|---|
| `{{name}}` (or `{{title}}`) | box name |
| `{{ip}}`, `$TARGET_IP`, `${TARGET_IP}` | target IP; `$TARGET_IP` also follows every later IP change |
| `{{hosts}}` | hostnames, comma separated |
| `{{date}}` | today, `2026-10-14` |
| `ip:` (an empty frontmatter line) | `ip: <ip>` |

dropzone takes the first template it finds:

1. `template` from the config: an absolute path, a path inside the vault (`notes = vault`) or inside `~/.config/dropzone/`
2. `~/.config/dropzone/templates/box-note.md`: your own copy, `install.sh` puts it there once
3. [`templates/box-note.md`](../templates/box-note.md) that ships with dropzone

Edit your copy as much as you like: add sections, translate headings, drop what you don't use. Keep `## Timeline` and the flag lines if you want `dz -j`, `dz -s` and `dz -f` to write into them (or set `timeline` to your own heading). `status:` in the frontmatter is what `dz -v` shows.

## What dropzone writes into the note

| Command | Where in the note |
|---|---|
| `dz -n` / `dz -ip` | the IP everywhere (exact match), `updated:` |
| `dz -j <text>` | `- <date> <time> · <text>` at the end of `## Timeline`; the section is added before `## Flags` when it's missing |
| `dz -s [caption]` | a timeline line with the screenshot embedded under it |
| `dz -f <flag>` | `- **User flag:** <flag>` / `- **Root flag:** <flag>`, or an Obsidian callout (see below); a `## Flags` section is added when it's missing |
| `dz -c user:secret` | a row in the first table under `## Credentials` |
| `dz -d` / `dz -a` / root flag | `status: done` and `updated:` in the frontmatter |

The note is never overwritten: dropzone only fills empty slots and adds lines.

## Obsidian

Two ways, both in **[examples/obsidian](../examples/obsidian/)** with a template that uses callouts and a Dataview dashboard:

- **Open `~/boxes` as a vault** and keep `notes = folder`. Nothing else to set up.
- **Your own vault** with `notes = vault`:

  ```ini
  [notes]
  notes = vault
  vault = ~/Documents/MyVault
  vault_folder = Boxes
  template = Templates/Box-note.md
  ```

  The vault can be local, mounted from another machine (virtiofs, NFS, SMB) or synced (Syncthing, Obsidian Sync, git). dropzone only needs to be able to write to the folder.

## Updates

Your template, notes and config live outside the dropzone folder, so `dz --update` never touches them. A better bundled template in a new version doesn't replace yours; compare with [`templates/box-note.md`](../templates/box-note.md) and copy what you like.
