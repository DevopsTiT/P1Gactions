# EIP MQ And AGPO Separate Terraform Files

## Decision tree

```
Seq 6: 2 alerts in 1 tf with for_each
 Want one file per alert?
  yes → split into 3 files in the same folder
   providers.tf                          → terraform + provider block (only once per folder)
   eip-mq-conn-timeout.tf                → resource eip_mq_conn_timeout
   agpo-auth0-password-sync-error.tf     → resource agpo_auth0_password_sync_error
 Already applied seq 6?
  yes → resource addresses changed → add moved blocks or terraform state mv (see below)
  no  → just plan and apply this folder
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | Each alert has its own tf file. Queries and settings are identical to seq 6. |
| Why a third file? | Terraform reads all tf files in a folder together; the provider must be declared only once. |
| Resource names | `eip_mq_conn_timeout` and `agpo_auth0_password_sync_error` |
| for_each? | Removed; each file has a plain resource |
| Apply with seq 6 too? | No. Use one folder only. |

## Summary

The two detectors from seq 6 now live in separate files, so each alert can be reviewed, changed, or deleted on its own. A shared providers file holds the Terraform and Dynatrace provider block.

## Files

| File | Contains |
|---|---|
| `7-eip-mq-agpo-auth0-separate-tf-providers.tf` | `terraform` block and `provider "dynatrace"` |
| `7-eip-mq-agpo-auth0-separate-tf-eip-mq-conn-timeout.tf` | MQ timeout detector, medium, pagerduty `"0"` |
| `7-eip-mq-agpo-auth0-separate-tf-agpo-auth0-password-sync-error.tf` | AGPO password sync detector, high, pagerduty `"1"` |

## MQ timeout query

```
fetch logs, from:now()-2m
| filter matchesValue(host.name, "wpalja21b*")
| filter contains(content, "Connection timed out", caseSensitive:false)
| fields timestamp, host.name, log.source, content
| fieldsAdd check = "eip_mq_conn_timeout"
```

## AGPO password sync query

```
fetch logs, from:now()-5m
| filter startsWith(host.name, "agpo-cloud-authorization-process-api-") or startsWith(k8s.pod.name, "agpo-cloud-authorization-process-api-")
| filter contains(content, "IamCChangePasswordBadRequestResponse", caseSensitive:false)
      or contains(content, "IamCChangePasswordNotFoundResponse", caseSensitive:false)
| summarize count = count()
| filter count > 1
| fieldsAdd check = "agpo_auth0_password_sync_error"
```

## If seq 6 was already applied

| Old address (seq 6) | New address (seq 7) |
|---|---|
| `dynatrace_davis_anomaly_detectors.eip_agpo_alerts["eip_mq_conn_timeout"]` | `dynatrace_davis_anomaly_detectors.eip_mq_conn_timeout` |
| `dynatrace_davis_anomaly_detectors.eip_agpo_alerts["agpo_auth0_password_sync_error"]` | `dynatrace_davis_anomaly_detectors.agpo_auth0_password_sync_error` |

Without a move, `terraform plan` would destroy and recreate both detectors. The `terraform state mv` one-liners are in `7.sh`.

## Data flow

```
providers.tf ─┐
eip-mq-conn-timeout.tf ─┼→ terraform plan (one folder) → 2 detectors in Dynatrace
agpo-auth0-password-sync-error.tf ─┘
```

## Investigation

| What was checked | Finding |
|---|---|
| Seq 6 tf | One `for_each` resource with 2 keys |
| Terraform folder rule | All tf files in a folder form one configuration |
| Provider block | Must appear once, so it moved to its own file |

## Result

| Step | What to do |
|---|---|
| 1 | Use this folder instead of seq 6 |
| 2 | If seq 6 was applied, run the two `terraform state mv` commands first |
| 3 | `terraform plan` should show 2 to add (or no changes after state mv) |
| 4 | Run the seq 6 check queries before apply |

## Related files

| File | Purpose |
|---|---|
| 3 tf files above | Provider and the two detectors |
| `7-eip-mq-agpo-auth0-separate-tf-check.dql` | Same check queries as seq 6 |
| `7.sh` | Commands |

## Commands

See `7.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/7-eip-mq-agpo-auth0-separate-tf"
terraform init
terraform validate
terraform plan
```
