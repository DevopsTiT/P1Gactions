# Confirm The Log Path Decision

```
Confirm the four checks
  1 purpose
    open CEAA20F7 and CEAA9026
    CEAA20F7 shows only FileNet → purpose is claim-payment hosts only → stop
    CEAA20F7 shows /app/ICM_CPW → continue
  2 file
    known hosts return the path in DQL
    CEAA20F7 returns 0 rows → that only means Dynatrace does not store it yet
    owner runs ls on the server
    file missing or old → stop
    file present and recent → continue
  3 host group
    host page shows HOST_GROUP-9034BF4FC7D158B2
    Hosts filter lists every member
    a member should not send this file → stop
    every member should send it → continue
  4 mask
    Settings → Log Monitoring → Sensitive data masking
    no enabled rule covers this path and this group → stop
    an enabled rule covers both → both Terraform blocks can go in one change
```

| Check | Where you look | Confirmed when |
|---|---|---|
| Purpose | Host pages for CEAA20F7 and CEAA9026 | CEAA20F7 is running the ICM app that writes this file. |
| File | DQL, then `ls` on the server | The file exists on CEAA20F7 and its time is recent. |
| Host group | Host page, then the Hosts list | You have the full member list and each member should send this file. |
| Mask | Sensitive data masking | An enabled rule covers this path and this host group. |

## Summary

Confirm the four checks in order. Dynatrace can show who is in the host group and whether the three claim-payment hosts already store this file. Dynatrace cannot prove the file exists on CEAA20F7, because that host is not collecting it yet. The file check is a directory listing on the server. The mask check is the Sensitive data masking page.

## Investigation

| Source | What it fixes |
|---|---|
| Seq 2 note | The path, the three included hosts, CEAA20F7, and the host group id. |
| Seq 3 decision | The four questions. This note is how to answer them. |
| Screenshot limit | The custom source block was cut off after `scope`. Confirm the live setting, not the cropped photo. |

## Result

### 1. Purpose

Open two host pages and compare them.

| Host | Why this one |
|---|---|
| CEAA9026 | A host that already collects the path. This is the picture of “ICM app”. |
| CEAA20F7 | The host the note wants to add. This is the picture you are judging. |

On each host, read the process list and any log path that mentions `ICM_CPW` or FileNet.

| What you see on CEAA20F7 | Decision |
|---|---|
| The same ICM app path you see on CEAA9026 | Continue to the file check. |
| FileNet processes and no `ICM_CPW` path | Purpose is the three claim-payment hosts. Leave this group out. |

The host label `FILENETFN` is a hint. The process list is the confirmation.

### 2. File

Run this in a Dynatrace Notebook. Leave the time picker at Last 2 hours. If the three hosts are quiet in that window, widen it to Last 7 days and run it again.

```
fetch logs
| filter contains(log.source, "/app/ICM_CPW/log/ap/default.log", caseSensitive:false)
| summarize lines = count(), by: { host.name }
| sort host.name asc
```

| Result | What it confirms |
|---|---|
| Rows for CEAAI016, CEAA9026, and CEAA9027 | The query works, and those hosts store this file. |
| A row for CEAA20F7 | This host already stores the file. The Terraform gap may already be closed. |
| No row for CEAA20F7 | Dynatrace is not storing this file for that host. The file can still exist on disk. |

The disk check is separate. Someone who can log in to CEAA20F7 runs:

```
ls -l /app/ICM_CPW/log/ap/default.log
```

| `ls` result | Decision |
|---|---|
| No such file | Stop. Do not add the matcher. |
| The file is there and the date is old | Stop. A file that nobody writes is not a reason to store it. |
| The file is there and the date is today | Continue to the host group. |

### 3. Host group

On the CEAA20F7 host page, open Properties and read Host group.

| What you read | Meaning |
|---|---|
| `HOST_GROUP-9034BF4FC7D158B2` | The note’s scope matches this host. |
| A different group id | The snippet is aimed at the wrong group. Stop and correct the scope. |

Then open Infrastructure, Hosts, and filter by that host group. Write down every hostname.

This DQL lists the same members. Use it when the filter is hard to find.

```
fetch dt.entity.host
| filter dt.entity.host_group == "HOST_GROUP-9034BF4FC7D158B2"
| fields entity.name, id
| sort entity.name asc
```

| Member list | Decision |
|---|---|
| Only hosts that write this ICM file | The group scope is safe. Continue to the mask. |
| Any host that does not write this file | Do not use this group. Ask for a smaller scope. |

### 4. Mask

Open Settings, Log Monitoring, Sensitive data masking.

For each enabled rule, read two things.

| Field on the rule | What you need |
|---|---|
| Scope | This host group, or a scope that includes CEAA20F7. |
| Matcher | `log.source` contains `/app/ICM_CPW/log/ap/default.log`, or a content rule that applies to logs in that scope. |

| What you find | Decision |
|---|---|
| No enabled rule covers this path and this group | Leave `send_to_storage` off. |
| An enabled rule covers both | Add the custom log source and the log storage block in one change. |

Also open the existing custom log source for the three claim-payment hosts and compare it with the photo. The photo stops after `scope`. The live rule shows the path matcher the new block still needs.

## Data flow map

```
CEAA9026 host page
  ICM app visible
        |
        v
CEAA20F7 host page
  same ICM app?  --no--> stop
        |
       yes
        v
Notebook DQL on the log path
  three hosts return rows
  CEAA20F7 has no row
        |
        v
ls on CEAA20F7
  file missing or old --> stop
  file present and recent
        |
        v
Host group member list
  extra hosts that should not send it --> stop
  every member should send it
        |
        v
Sensitive data masking
  rule missing --> storage stays off
  rule covers path and group --> one Terraform change
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | The confirmation order. |
| `1-investigation.md` | Which earlier note each check comes from. |
| `2-result.md` | The screen or command for each check. |
| `3-glossary.md` | Terms. |
| `4-confirm-log-path-decision-follow.txt` | The same steps for a phone. |
| `4.sh` | The server listing and the copy commands. |

Commands: [4.sh](4.sh)
