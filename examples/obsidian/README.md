# Obsidian example

[README](../../README.md) · [Notes](../../docs/notes.md)

dropzone writes plain Markdown, so Obsidian works out of the box. This folder is one way to set it up: the way dropzone's author uses it.

| File | What it is |
|---|---|
| [`Box-note.md`](Box-note.md) | the box template with Obsidian callouts: column help that folds open, 4 phases, foldable flags |
| [`Box-note-extended.md`](Box-note-extended.md) | the same with all 8 PTES phases and a Findings table |
| [`Boxes-dashboard.md`](Boxes-dashboard.md) | a Dataview table of all boxes with status, IP and last update |

## Option 1: notes in the box folder

The simplest. Keep the default `notes = folder` and open `~/boxes` as a vault in Obsidian (*Open folder as vault*). Every box note is `~/boxes/<box>/notes.md`, screenshots show up straight away.

## Option 2: notes in your own vault

When you already have a vault, let dropzone write into it.

1. Copy `Box-note.md` to your vault, for example to `Templates/Box-note.md`.
2. In your config (`dz --config`):

   ```ini
   [notes]
   notes = vault
   vault = ~/Documents/MyVault
   vault_folder = Boxes
   template = Templates/Box-note.md
   attachments = Boxes/attachments
   ```

3. `dz -n test -ip 10.10.10.10` creates `Boxes/test.md` in your vault. `dz -o` opens it in Obsidian.

Want the extended note for some boxes? Copy `Box-note-extended.md` next to it as `Templates/box-note-extended.md`; `dz -n <name> -ip <ip> --template box-note-extended` finds it there. Without a copy it uses the bundled one, in plain Markdown.

Screenshots from `dz -s` stay in `~/boxes/<box>/evidence/` and get a copy in `attachments`, because Obsidian only shows images inside the vault.

## An exam note

dropzone ships an exam template too ([`templates/exam-note.md`](../../templates/exam-note.md)): Scope, Hosts with a *Via* column, To do, a Findings table, Host notes and flags per host. Copy it next to your box template as `Templates/Exam-note.md`, and `dz -n <name> -ip <ip> --template exam` finds it there. Without a copy, `--template exam` uses the bundled one.

## Where the vault lives

dropzone only needs the vault as a folder it can write to. It doesn't matter how it gets there:

- **Local**: Obsidian and dropzone on the same machine.
- **Mounted**: the vault lives on another machine and is mounted on Kali, for example a Proxmox virtiofs share, NFS or SMB. Set `vault` to the mount point.
- **Synced**: Syncthing, Obsidian Sync or a git repo keeps a copy on Kali in sync with your main machine.

## Templates and updates

Your template lives in your vault, so `dz --update` never touches it. dz writes into sections by heading (`## To do`, `## Findings`, `## Timeline`, `## Flags` and the tables): keep the ones you use, or set `timeline = <your heading>`. With `add_sections = no` dz never adds a section to your note, see [notes.md](../../docs/notes.md#templates).

`dz --todo` writes plain `- [ ]` checkboxes, so ticking one off in Obsidian is the same as `dz --todo done <nr>`.
