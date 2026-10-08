# Banca Portal Real Time And Functional NG TF

## Decision tree

```
Jenkins build_report on ceaa2099 (source jenkins/test)
  job_result ABORTED or FAILURE? -> dropped
  Real Time Check or Functional job under App-Ops-OpenOps?
    yes -> map both to one project "name"
           -> configuration lookup: application == "Banca Portal"?
                yes -> Real Time: 2+ non-SUCCESS and 0 SUCCESS in 2 hours?
                         yes -> problem per project (high, PagerDuty on)
                         next SUCCESS -> problem closes
Never fires?
  -> check.dql query 1 (job_name values) and query 2 (configuration rows for Banca Portal)
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this new logic? | No. It is the same search as AG Portal NTTGW (seq 19). |
| What changed from seq 19? | Application "Banca Portal", time range 2 hours, cron every minute. |
| When does it fire? | Real Time job returned 2 or more non-SUCCESS results with no SUCCESS in 2 hours. |
| Identity | `application` and `name`, one problem per project. |
| Severity | high. |
| PagerDuty | "1" (PagerDuty Enable). URL not copied. |

## Summary

Banca Portal uses the same Splunk search template as AG Portal NTTGW. Only the application filter, the 2-hour window and the every-minute schedule differ, so the detector is the seq 19 query with `cfg.application == "Banca Portal"` and `from:now()-2h`.

## Differences from seq 19

| Setting | AG Portal NTTGW (seq 19) | Banca Portal (this one) |
|---|---|---|
| `where application=` | "AG Portal NTTGW" | "Banca Portal" |
| Time range | Last 30 minutes | Last 2 hours |
| Cron | Every 30 minutes | Every minute |
| PagerDuty | Enable | Enable |
| Email mode | Production | Production |

## Terraform

Full file: `20-banca-portal-realtime-functional-ng-tf.tf`. The query is the seq 19 query with two changes:

```
fetch logs, from:now()-2h
...
| filter cfg.application == "Banca Portal"
...
| filter rt_fails >= 2 and rt_oks == 0
```

## Not migrated

| Item | What to do |
|---|---|
| Failed Functional test names | Use check query 3 or the Jenkins build report. |
| Maintenance macro | Run the `.spl` macro query; add a maintenance lookup filter if needed. |
| PagerDuty URL | Keep it in the Dynatrace PagerDuty connection, not in tf. |

## Data flow

```
Jenkins (Real Time Check + Functional jobs)
  -> build_report JSON on ceaa2099 -> Grail
  -> Records detector (every minute, last 2 hours) + configuration lookup (Banca Portal)
  -> 2+ NG, 0 SUCCESS -> problem per project (high) -> PagerDuty + email
  -> next SUCCESS -> closes
```

## Investigation

| What I checked | What I found |
|---|---|
| Search body | Same as seq 19 line by line, except `where application="Banca Portal"`. |
| Schedule | cron */1, Last 2 hours. |
| Trigger | results > 0, Once, no throttle. |
| Action | Alert Status Manager, Production, PagerDuty Enable. |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 2 to confirm Banca Portal rows exist in configuration. |
| 2 | Run query 1 to confirm job names match the tf strings. |
| 3 | `terraform plan` and `terraform apply` from `20.sh`. |

## Related files

| File | What it is |
|---|---|
| `20-banca-portal-realtime-functional-ng-tf.tf` | The detector |
| `20-banca-portal-realtime-functional-ng-tf-check.dql` | Dynatrace checks |
| `20-banca-portal-realtime-functional-ng-tf.spl` | Splunk checks |
| `20.sh` | Commands |
| `../19-ag-portal-nttgw-realtime-functional-ng-tf/` | Same template for AG Portal NTTGW |

## Commands

From `20.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/20-banca-portal-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
