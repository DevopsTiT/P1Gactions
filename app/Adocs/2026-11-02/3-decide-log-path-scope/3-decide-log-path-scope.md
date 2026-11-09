# Decide The Log Path Scope

```
Add /app/ICM_CPW/log/ap/default.log to CEAA20F7's host group?
  what are you trying to see?
    claim-payment logs only
      CEAA20F7 is labeled FileNet → leave the group out
    this same file on this host
      file missing on the server → leave it out
      file present
        other hosts in HOST_GROUP-9034BF4FC7D158B2
          they should not send this file → do not use this group scope
          they should send it → continue
        personal data in the file
          mask does not cover this path → do not turn on storage yet
          mask covers this path → add custom source and log storage together
```

| Question | A yes means |
|---|---|
| Is the goal claim-payment logs only? | CEAA20F7 stays out. It is labeled FileNet. |
| Does CEAA20F7 write this file? | The path is real on that server. |
| Is every host in the group supposed to send it? | The host-group scope is safe. |
| Does the mask cover this path? | Storage can be turned on. |

## Summary

Make the call in four steps: purpose, file on the server, who else is in the host group, then the personal-data mask. Add the Terraform only when the file is really on those hosts and the mask already covers that path. The custom source and the storage block go in together.

## Investigation

| Source | What it already told us |
|---|---|
| Teams note | The path is collected for CEAAI016, CEAA9026, and CEAA9027. |
| Same note | The path is not collected for CEAA20F7. |
| Host label | CEAA20F7 is `FILENETFN`. The three others are `ICMCLMPAY`. |
| Proposed scope | `HOST_GROUP-9034BF4FC7D158B2`, which is a group, not one hostname. |
| Chat title | Masking PII data in Dynatrace. The note does not show a mask. |

## Result

Walk the questions in this order. Stop at the first no.

| Step | Check | No | Yes |
|---|---|---|---|
| 1. Purpose | Do you need this ICM log from the FileNet host, or only from the claim-payment hosts? | Leave CEAA20F7 out. The three hosts already have the path. | Go to step 2. |
| 2. File | On CEAA20F7, does `/app/ICM_CPW/log/ap/default.log` exist and get new lines? | Do not add the resources. A matcher for a missing file stores nothing. | Go to step 3. |
| 3. Scope | In Dynatrace, open host group `HOST_GROUP-9034BF4FC7D158B2` and list the hosts. Should each of them send this file? | Do not put the rule on the group. Ask for a host-sized scope, or a group that contains only the right hosts. | Go to step 4. |
| 4. Mask | Does the existing mask rule match this `log.source` path? | Keep `send_to_storage` off until the mask covers the path. The meeting is about personal data. | Add both Terraform blocks in the same change. |

The two blocks do different jobs.

| Block | Decision it belongs to |
|---|---|
| `dynatrace_log_custom_source` | The agent reads the file. |
| `dynatrace_log_storage` with `send_to_storage = true` | Dynatrace keeps the lines. |

A custom source without storage reads the file and does not keep it. Storage without a custom source has nothing new to match if the agent never reads the file. Put them in one change after step 4 is yes.

The resource is named `alj_icmclmpay_prod_app` while the host label says FileNet. That name mismatch is the reason for step 2. Do not treat the Terraform comment as proof the file is there.

## Data flow map

```
Purpose
  claim-payment only → stop, three hosts already covered
  need CEAA20F7 too
        |
        v
File on CEAA20F7?
  no → stop
  yes
        |
        v
Every host in HOST_GROUP-9034BF4FC7D158B2?
  no → stop, do not use this group
  yes
        |
        v
Mask matches this log path?
  no → stop, storage stays off
  yes
        |
        v
One change
  custom log source
  log storage, send_to_storage true
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | The decision order. |
| `1-investigation.md` | Facts already on the note. |
| `2-result.md` | The four checks. |
| `3-glossary.md` | Terms. |
| `3-decide-log-path-scope-follow.txt` | The same decision for a phone. |
| `3.sh` | Copy commands. |

Commands: [3.sh](3.sh)
