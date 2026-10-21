# Testing

[README](../README.md) · [Guide](guide.md) · [Commands](commands.md) · [Notes](notes.md) · [Config](config.md) · [Errors](errors.md) · **Testing** · [Development](development.md)

What the automatic tests cover, and what can only be confirmed by hand on a real Kali with a desktop, a VPN and real targets. Tested something? Change its status in a pull request, with the date and your setup.

- [Automatic tests](#automatic-tests)
- [Manual checks](#manual-checks)
- [How to test by hand](#how-to-test-by-hand)

## Automatic tests

`zsh tests/run.zsh` runs on every push, on Ubuntu and in a Kali container (see [development.md](development.md#run-the-tests)). Each test file gets a temporary `HOME`, its own hosts file and a fake vault; tools that need a desktop, network or another program are stubbed:

| Area | Covered automatically | Stubbed, so not really tested |
|---|---|---|
| Boxes, hosts, notes, flags, creds, deadline, config, errors | everything | – |
| `dz -s` | file names, vault copy, embed, which tool on X11 and Wayland, the grim/slurp and spectacle arguments | the screenshot tool itself |
| `dz -e` | file, command from the log, code block | – |
| To-dos, findings, `dz -i <host>` | adding, ticking off, numbering, evidence under a finding, the Findings table, `add_sections = no`, special characters | – |
| `dz -cp` | values, secrets not printed | the real clipboard (`xclip`, `wl-copy`) |
| `dz serve` | commands, bind address, refusals, `--via` | `python3 -m http.server`, `impacket-smbserver`, ligolo |
| VPN check | the logic for tun0, other routes and pivots | `ip route` on a real VPN |
| SysReptor | what is sent, opt-in, missing `reptor` | `reptor` and a SysReptor server |
| `/etc/hosts` | lines, tags, backup | `sudo` and the real `/etc/hosts` |
| Menu | submenus, greyed items, the host list, the status line, the 10 arts fit | the keys and forms in a real terminal over RDP or SSH |

## Manual checks

Status: **open** (not tested by hand yet) or the date it was confirmed.

### Desktop and terminal

| Check | Since | Status |
|---|---|---|
| `dz -s`: region selection with the mouse, PNG in `evidence/` and in the note | 1.0.0 | open |
| `dz -s` from a keyboard shortcut (`zsh -ic 'dz -s'`) lands in the loaded box | 1.0.0 | open |
| `dz -c <user>`: the secret prompt shows nothing while typing | 1.0.0 | open |
| `dz -h <host>`: sudo asks for the password, the line is in `/etc/hosts` | 1.0.0 | open |
| `dz -cp` / `dz -cp pass`: the value is on the clipboard (X11 and Wayland) | 1.1.0 | open |
| `dz -s` on Wayland: `grim` + `slurp` (sway, Hyprland) and `spectacle` (KDE) select a region, PNG in the note | 1.3.0 | open |
| The menu over RDP: arrows, Enter, Esc, forms | 1.0.0 | open |
| The menu: *Target ›* and *Notes ›*, every item once, `q` goes back; the secret in *Creds* stays hidden | 1.3.0 | open |
| The 10 arts over RDP: each one shows whole, `DZ_ART=1` to `DZ_ART=10 dz` | 1.3.0 | open |
| `output = yes`: a new terminal records with `script(1)`, `exit` closes it | 1.0.0 | open |
| `--deadline`: the prompt counts down, turns red in the last 6 hours, `time's up` after | 1.2.0 | open |

### Network

| Check | Since | Status |
|---|---|---|
| VPN check: no warning on the HTB VPN, `[W201]` with the VPN down, `[W202]` for an IP outside it | 1.1.0 | open |
| VPN check: no warning for a host behind a ligolo-ng tunnel (`ligolo` interface) | 1.1.5 | open |
| `dz serve`: a Linux and a Windows target download a file with the printed command | 1.1.0 | open |
| `dz serve smb`: a Windows target copies a file from the share | 1.1.0 | open |
| `dz serve --via`: the printed `listener_add` works in ligolo-ng, a host behind the pivot downloads the file | 1.1.5 | open |

### Creds, evidence and notes

| Check | Since | Status |
|---|---|---|
| `dz -c 'user:loot/x.ccache'`: `$KRB5CCNAME` works with impacket / nxc `-k` | 1.2.0 | open |
| `dz -c 'user:loot/id_rsa'`: `ssh -i $SSH_KEY user@$TARGET` logs in | 1.2.0 | open |
| `dz -c --export`: nxc takes `loot/users.txt` and `loot/passwords.txt` | 1.2.0 | open |
| `cmd 2>&1 \| dz -e`: a real tool's output (colours, progress bars) reads well in the note | 1.2.0 | open |
| `notes = vault`: screenshots show in Obsidian, `dz -o` opens the note | 1.0.0 | open |
| `--template exam` in Obsidian: tables, Host notes headings, flag list, timeline code blocks render well | 1.2.0 | open |
| `dz --todo` in Obsidian: the checkboxes render, ticking one off in Obsidian shows in `dz --todo` | 1.4.0 | open |
| `dz --finding` + `dz -s` / `dz -e` in Obsidian: the Findings table stays intact, screenshots and code blocks show under the finding | 1.4.0 | open |
| `dz -i` and `dz -i <host>` on a real exam box: the Next block and the host view read well | 1.4.0 | open |
| The menu: *Notes › To do* and *Notes › Finding* | 1.4.0 | open |
| `sysreptor = yes`: a screenshot and a `dz -e` output arrive in the project's notes, under the box | 1.2.0 | open |

### Updates

| Check | Since | Status |
|---|---|---|
| `dz --update` on a real clone shows the changes and keeps config, templates and boxes | 1.0.0 | 2026-10-14, Kali 2026.2 (1.0.0 → 1.1.0) |
| `dz --config check` after an update lists the new settings | 1.0.0 | open |

## How to test by hand

- Test on the version you're checking: `dz --version`, and `exec zsh` after `dz --update`.
- Use a box you can throw away: `dz -n dztest -ip <lab-ip>`, and `dz -r dztest -y --note` after.
- For network checks you need a lab you're allowed to test (HTB, your own homelab). dz itself never sends anything to a target, but the commands you run with it do.
- Write down what you saw when it fails: the command, the output (with the error code), `dz --version`, your distro and desktop. An issue with that is quick to fix.
