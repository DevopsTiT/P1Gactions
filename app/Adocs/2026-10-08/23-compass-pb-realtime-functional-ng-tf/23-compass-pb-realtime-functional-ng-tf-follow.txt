# Compass PB Real Time And Functional NG TF

## Decision tree

```
Jenkins build_report on ceaa2099 (source jenkins/test)
  ABORTED or FAILURE? -> dropped
  Real Time Check or Functional job under App-Ops-OpenOps? -> one project "name"
    configuration lookup: application == "Compass AG"?
      yes -> Real Time 2+ non-SUCCESS and 0 SUCCESS in 2 hours?
               yes -> problem per project (high, PagerDuty on), remarks shows maintenance
               next SUCCESS -> closes
Never fires?
  -> query 2: Compass AG rows in configuration
```

## Short takeaway

| Question | Answer |
|---|---|
| Template | Same as Banca Portal (seq 20). |
| What is new? | The "OKメンテナンス中" remark is extracted and shown as `remarks`. |
| Application filter | "Compass AG" (the alert name says Compass PB). |
| Window | 2 hours, cron every minute. |
| Severity | high. |
| PagerDuty | "1" (Enable). URL not copied. |

## Summary

Compass PB is the seq 20 detector with the application set to "Compass AG" and one extra field: `remarks`, which shows "OKメンテナンス中" when a run reported it was under maintenance. Everything else, including the 2-hour window and PagerDuty Enable, matches Banca Portal.

## Differences from seq 20

| Setting | Banca Portal (seq 20) | Compass PB (this one) |
|---|---|---|
| `where application=` | "Banca Portal" | "Compass AG" |
| Maintenance remark | None | `rex "OKメンテナンス中"` kept in stats and table |
| Time range | Last 2 hours | Last 2 hours |
| Cron | Every minute | Every minute |
| PagerDuty | Enable | Enable |

## Terraform

Full file: `23-compass-pb-realtime-functional-ng-tf.tf`. Changes to the seq 20 query:

```
| fieldsAdd remark = if(contains(content, "OKメンテナンス中"), "OKメンテナンス中")
...
| filter cfg.application == "Compass AG"
...
| summarize ..., remarks = collectDistinct(remark), ...
```

## Data flow

```
Jenkins (Real Time Check + Functional jobs)
  -> build_report JSON on ceaa2099 -> Grail
  -> Records detector (every minute, last 2 hours) + configuration lookup (Compass AG)
  -> 2+ NG, 0 SUCCESS -> problem per project (high) -> PagerDuty + email
  -> next SUCCESS -> closes
```

## Investigation

| What I checked | What I found |
|---|---|
| Search body | Same as seq 20, plus `rex field=_raw ".+?(?<remarks>OKメンテナンス中)"`. |
| Application | "Compass AG". |
| Schedule | cron */1, Last 2 hours. |
| Trigger | event=2 or recovery, results > 0, Once, no throttle. |
| Action | Alert Status Manager, Production, PagerDuty Enable. |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 2 to confirm Compass AG rows in configuration. |
| 2 | Run query 1 to confirm job names match the tf strings. |
| 3 | `terraform plan` and `terraform apply` from `23.sh`. |

## Related files

| File | What it is |
|---|---|
| `23-compass-pb-realtime-functional-ng-tf.tf` | The detector |
| `23-compass-pb-realtime-functional-ng-tf-check.dql` | Dynatrace checks |
| `23-compass-pb-realtime-functional-ng-tf.spl` | Splunk checks |
| `23.sh` | Commands |
| `../20-banca-portal-realtime-functional-ng-tf/` | Same template for Banca Portal |

## Commands

From `23.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/23-compass-pb-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
