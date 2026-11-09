# Dynatrace Log Path Gap

```
Chat: is /app/ICM_CPW/log/ap/default.log collected?
  three ICM claim-payment hosts → yes, already in Terraform
  CEAA20F7 → no
    its host group is HOST_GROUP-9034BF4FC7D158B2
    the note asks main.tf to add two resources on that group
      log storage → keep matching lines
      custom log source → tell the agent to read the file
  before apply
    does this FileNet host actually write that ICM log?
    a host-group rule hits every host in the group
    this chat is about PII masking, and the mask rule is not in the note
```

| Key point | Detail |
|---|---|
| Log file | `/app/ICM_CPW/log/ap/default.log`. |
| Already collected | CEAAI016, CEAA9026, and CEAA9027. |
| Not collected | CEAA20F7. |
| Proposed scope | Host group `HOST_GROUP-9034BF4FC7D158B2`. |
| Two blocks | `dynatrace_log_storage` and `dynatrace_log_custom_source`. |

## Summary

The Teams note says Dynatrace log collection for one ICM log file is turned on for three claim-payment hosts and left out for CEAA20F7. The Terraform in the note would turn that file on for CEAA20F7’s host group. A host-group setting applies to every host in the group. The chat title is about masking personal data, and this note does not show the mask rule.

## Investigation

| Source | Finding |
|---|---|
| Chat | Daily Standup: Masking PII data in Dynatrace. |
| Author | LAKSHMI Arunachalam. |
| Log path | `/app/ICM_CPW/log/ap/default.log`. |
| Included hosts | CEAAI016, role text `ICMCLMPAY` and `PROXY`. CEAA9026 and CEAA9027, role text `ICMCLMPAY` and `APP`. |
| Excluded host | CEAA20F7, role text `FILENETFN` and `APP`, plus `HOST_GROUP-9034BF4FC7D158B2`. |
| First resource | `dynatrace_log_storage.alj_icmclmpay_prod_app`. `send_to_storage = true`. Matcher `log.source` `MATCHES` that path. |
| Second resource | `dynatrace_log_custom_source.alj_icmclmpay_app_logs`. `enabled = true`. Same host group. The screenshot cuts off after `scope`. |

## Result

A log source is the file path on the server. “Included” means the Dynatrace agent is configured to read that file and send the lines into Dynatrace storage.

The three included machines are claim-payment hosts. Two are app hosts and one is a proxy. CEAA20F7 is labeled as a FileNet app host, and it sits in a different host group. That is why the same path can be present for the three and absent for this one. The rule was written for the other group.

The note says `main.tf` should add two blocks on `HOST_GROUP-9034BF4FC7D158B2`.

| Block | What it does |
|---|---|
| `dynatrace_log_storage` | Keeps log lines whose `log.source` matches `/app/ICM_CPW/log/ap/default.log`. `send_to_storage = true` means those lines are stored. |
| `dynatrace_log_custom_source` | Tells the agent on that host group to pick up this file. The rest of the block is below the photo. |

`MATCHES` means the path has to match that string. `scope` is the host group, not the single hostname. Every host in `HOST_GROUP-9034BF4FC7D158B2` would get the rule.

Check two things before that Terraform is applied.

| Check | Why |
|---|---|
| The file exists on CEAA20F7 | The resource name says `icmclmpay`. The host label says FileNet. Confirm this server writes `/app/ICM_CPW/log/ap/default.log`. |
| Who else is in that host group | The change is not limited to CEAA20F7. |
| The PII mask for this path | The meeting title is masking personal data. This note does not show a mask. Storing the file is a separate step from hiding personal data inside it. |

## Data flow map

```
/app/ICM_CPW/log/ap/default.log
        |
        +--> CEAAI016, CEAA9026, CEAA9027
        |      Terraform already includes the path
        |      agent reads the file
        |      lines go to Dynatrace storage
        |
        +--> CEAA20F7
               path is not in its host group today
               proposed main.tf
                 custom log source on HOST_GROUP-9034BF4FC7D158B2
                 log storage MATCHES that path
                 send_to_storage = true
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | What the note is deciding. |
| `1-investigation.md` | Hosts and the two Terraform blocks. |
| `2-result.md` | What the blocks do, and what to confirm. |
| `3-glossary.md` | Terms. |
| `2-dynatrace-log-path-gap-follow.txt` | The same explanation for a phone. |
| `2.sh` | Copy commands. |

Commands: [2.sh](2.sh)
