# Guide

[README](../README.md) · **Guide** · [Commands](commands.md) · [Notes](notes.md) · [Config](config.md) · [Errors](errors.md) · [Testing](testing.md) · [Development](development.md)

What you really need to know to use dz without surprises. Every option is in [commands.md](commands.md); this page is about how dz behaves.

- [How dz works](#how-dz-works)
- [Ten things that trip people up](#ten-things-that-trip-people-up)
- [Your note](#your-note)
- [Secrets](#secrets)
- [An exam with dz](#an-exam-with-dz)
- [When something goes wrong](#when-something-goes-wrong)

## How dz works

- **dz is a shell function, not a program.** It runs inside your zsh, so it can `cd` you into the box folder and set `$TARGET_IP` and the other variables in *your* shell. That's also why it only works in zsh, and why an update needs `exec zsh` (or a new terminal) before you have the new version.
- **Variables live per terminal.** `dz -l` in one terminal doesn't change a terminal that is already open. New terminals load the last box you loaded (`autoload = yes`), including the active host from `dz -t`. Run `dz -l <box>` in an old terminal to bring it up to date.
- **One action per call.** `dz -l jacops -i` is refused ([E103](errors.md#e103)): first `dz -l jacops`, then `dz -i`. Options that only change how an action works (`-ip`, `-h`, `--via`, `--template`, `--deadline`, `-y`, `--all`) can go along.
- **dz never touches the target.** It doesn't scan, exploit or connect, apart from one ping after `-n` / `-ip` (`ping = no` turns that off). `dz serve` and `dz -cp` only print or copy commands; you run them.
- **Files are read, never run.** `.dropzone`, `creds`, `.via`, `.deadline` and your config are parsed line by line, so a dumped `.env` or other loot in a box folder can't run code on your Kali.

## Ten things that trip people up

1. **`-h` has two meanings.** `-h` alone is help; `-h <host,...>` sets hostnames. `dz -n jacops -ip 10.10.10.5 -h` (nothing after it) shows the help.
2. **`!` in a password.** zsh expands `!` in double quotes and unquoted words. Use single quotes: `dz -c 'alex:Pass!2026'`, or `dz -c alex` and type the secret at the prompt.
3. **Secrets in your history.** A secret on the command line ends up in `~/.zsh_history`. `dz -c <user>` asks for it without echo, or start the line with a space (that also keeps it out of `commands.log`).
4. **`-j`, `-s` and `-e` take the rest of the line.** `dz -j found creds --help` writes "found creds --help" into the timeline; it doesn't show the help. Quotes are optional.
5. **`cmd | dz -e` only gets stdout.** Errors from the tool go to stderr and aren't piped: add `2>&1`. And you don't see the output while it's piped; add `| tee /dev/tty` before `| dz -e` to watch it.
6. **`/etc/hosts` needs sudo.** `-h` and `dz -t ... -h` ask for your sudo password. dz keeps a backup in `/etc/hosts.dz.bak` and only touches lines tagged `# dz:<box>`.
7. **The note is never overwritten**, also not by `dz -n` on an existing box or by a new template. A changed template only counts for new boxes.
8. **Headings are how dz finds its place.** Rename `## Timeline`, `## Flags`, `## Hosts`, `## Ports` or `## Credentials` and dz can't write there any more (or adds a new section). Keep them, or set `timeline` for your own timeline heading.
9. **The VPN check only warns.** A `[W201]` or `[W202]` never stops a command. It's there so you notice a dead VPN before you lose an hour.
10. **`dz -r` is a trash, `dz -a` is an archive.** Removing moves the box folder to the system trash (and the vault note only if you say so). Archiving keeps everything under `~/boxes/_archive/` and `dz -l` brings it back; `dz -r` also takes an archived box.

## Your note

- One note per box: `notes = folder` puts it in the box folder, `notes = vault` in your Obsidian vault. See [notes.md](notes.md).
- dz adds lines and fills empty slots: timeline, flags, host rows, ports, creds. Everything else in the note is yours.
- The IP in the note follows `dz -ip` and `dz -t <host> -ip`, as an exact match: `10.10.10.1` leaves `10.10.10.15` alone.
- Flags: a single box has a user and a root slot (the root flag marks it done). A box with more hosts, or a note without those slots like the exam template, keeps a list of flags per host with a count against `flag_goal`.

## Secrets

- Creds are **off** by default (`creds = yes` turns them on), because they are stored in plain text: in `~/boxes/<box>/creds` (only readable by you), in the note, and in the trash after `dz -r`.
- `dz -cp pass` copies a password without printing it; `dz -c` and `--creds` are logged as `<hidden>`. *Creds* in the menu doesn't show the secret while you type.
- `dz serve` never shares a box folder, your boxes folder, the archive or a folder above them. Serving `loot/` after `dz -c --export` gives `[W604]`: those lists are your creds.
- With `notes = vault`, the note with the creds table lands wherever your vault syncs to. With `sysreptor = yes`, screenshots and command output go to your SysReptor server. Think about that before an exam or a client job.

## An exam with dz

A run-through for a network exam like the HTB CPTS (one entry point, internal hosts behind a pivot, many flags, a report at the end):

<p align="center"><img src="../assets/hosts.gif" alt="dz -t: an exam box with a pivot host and a DC behind it, switching the target, a flag per host, dz -i and dz -g" width="85%"></p>

```bash
# config once: flag_goal = 14, creds = yes (and sysreptor = yes if you use it)
dz -n cpts -ip 10.129.5.10 -h inlanefreight.local --template exam --deadline 10d

nmap -p- -oA scans/ext $TARGET_IP && dz -p                 # your scan, ports into the note
dz -c 'svc_web:Welcome1' 'web config' --valid cpts          # a cred and where it works
dz -t web01 -ip 172.16.5.15                                 # the pivot's internal IP
dz -t ms01 -ip 172.16.5.10 --via web01                      # a host behind it
dz serve ~/tools --via web01                                # ligolo listener + download commands
nxc smb 172.16.5.0/24 2>&1 | dz -e smb sweep                # output as evidence
dz -c --export                                              # users/passwords/hashes for spraying
dz -t ms01 && dz -f <flag>                                  # flag of ms01, 3/14
dz -s ms01 local admin                                      # screenshot into the timeline
dz --deadline                                               # day 6/10 · 3d22h left
dz -g svc_sql --all                                         # seen that user on an earlier box?
```

## When something goes wrong

Every error and warning has a code: `dz [E201] no box loaded`, `• [W202] the route to ...`. `dz --explain E201` tells you why and what to do; [errors.md](errors.md) has the full list.

Things that aren't an error but look like one:

- **No variables in a new terminal**: `autoload = no`, or the last box was removed. `dz -l <box>`.
- **`$ATTACKER_IP` is empty**: the VPN interface is down or has another name (`iface`). It's read again before every prompt, at most every 10 seconds.
- **The prompt shows nothing**: `prompt = no`, or `$(_dz_prompt)` isn't in your `PROMPT` (see [config.md](config.md#prompt)).
