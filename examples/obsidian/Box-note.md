---
title: "{{name}}"
created: {{date}}
updated: {{date}}
status: active
ip: {{ip}}
os: 
platform: 
difficulty: 
tags: [box]
---

# {{name}}

> [!info] Target
> **IP:** $TARGET_IP · **Hostnames:** {{hosts}} · **Folder:** `~/boxes/{{name}}`
> **OS:** · **Platform:** · **Difficulty:**

## Overview

### Hosts

| Host | IP | Hostname / FQDN | OS | Via | Role / notes |
|---|---|---|---|---|---|
| {{name}} | {{ip}} | {{hosts}} | | | |

> [!info]- Columns
> - **Host**: a short name, the one you use with `dz -t`. E.g. `dc01`
> - **Hostname / FQDN**: from DNS, SMB or a TLS certificate. E.g. `dc01.inlanefreight.local`
> - **OS**: from the TTL (128 Windows, 64 Linux), `nmap -O` or banners. E.g. `Windows Server 2019`
> - **Via**: the pivot this host sits behind (`dz -t <host> --via`). E.g. `web01`
> - **Role / notes**: what it does. E.g. `Domain Controller`

### Ports & services

| Port | Proto | State | Service | Version | Notes |
|---|---|---|---|---|---|
| | | | | | |

> [!info]- Columns
> - Filled by `dz -p` from your own nmap output.
> - **Version**: product and version from `-sV`. E.g. `Samba smbd 4.6.2`
> - **Notes**: a lead. E.g. `null session allowed`

### Web / URLs

| URL / path | Status | Tech + version | Interesting | Notes |
|---|---|---|---|---|
| | | | | |

> [!info]- Columns
> - **Tech + version**: framework or CMS. E.g. `Nibbleblog 4.0.3`
> - **Interesting**: a login, upload, LFI or API. E.g. `admin login`
> - **Notes**: what to do with it. E.g. `default creds admin:nibbles`

### Other services

| Service (port) | Found | Lead / next |
|---|---|---|
| | | |

> [!info]- Columns
> - **Found**: what you got out of it. E.g. `DNS (53)`: AXFR works, 5 subdomains
> - **Lead / next**: the next step. E.g. `add internal.* to /etc/hosts`

## Credentials & secrets

> [!tip] Every cred in one place
> A cred from one service often works on another: try each new one everywhere.

| Source | Username | Secret | Valid on | Notes |
|---|---|---|---|---|
| | | | | |

> [!info]- Columns
> - Filled by `dz -c` (with `creds = yes`); `dz -c <nr> --valid <hosts>` fills *Valid on*.
> - **Source**: where you found it. E.g. `SNMP` / `gsconfig.php`
> - **Secret**: password, hash or key path. E.g. `lol123!mD`
> - **Valid on**: the hosts or services where it works. E.g. `dc01, ms01`

## To do

- [ ] 

## 1. Information Gathering

> [!abstract] Phase
> **Done when:** every open port, service, version and web app is in the Overview.
> **Next:** Exploitation.

> [!todo]- Checklist
> Your own checks for this phase.
> - [ ] 

> [!note]+ Notes
> 

### Walkthrough

```bash

```

### Results

- 

## 2. Exploitation

> [!abstract] Phase
> **Done when:** you have a shell or a login on the target.
> **Next:** Post-Exploitation · Lateral Movement · back to Information Gathering.

> [!todo]- Checklist
> Your own checks for this phase.
> - [ ] 

> [!note]+ Notes
> 

### Walkthrough

```bash

```

### Results

- 

## 3. Post-Exploitation

> [!abstract] Phase
> **Done when:** you are root or SYSTEM and looked through the host for loot.
> **Next:** Lateral Movement · Exploitation.

> [!todo]- Checklist
> Your own checks for this phase.
> - [ ] 

> [!note]+ Notes
> 

### Walkthrough

```bash

```

### Results

- 

## 4. Lateral Movement

> [!abstract] Phase
> **Done when:** you have access to the next host or account.
> **Next:** Information Gathering on the new host.

> [!todo]- Checklist
> Your own checks for this phase.
> - [ ] 

> [!note]+ Notes
> 

### Walkthrough

```bash

```

### Results

- 

## Findings

## Questions

**Question 1:** 
> [!success]- Answer
> 

**Question 2:** 
> [!success]- Answer
> 

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
