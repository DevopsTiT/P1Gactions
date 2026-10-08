# FCR NG Audit Trail Filter TF

## Decision tree

```
Same FCR alert as seq 25, plus a raw-data screenshot
  what is in jenkins_statistics?
    14.7M events, mostly audit_trail ("updated fingerprints ...", user SYSTEM)
    audit_trail has no job_name / job_result / job_duration
  -> detector only needs build events with job_duration
  -> first filters: contains "job_duration", not contains "audit_trail"
  -> logic unchanged (Real Time 2+ NG, 0 SUCCESS in 2h, application FCR)
Same fix for Cockpit360 (seq 22) and Compass (seq 24)?
  -> yes, swap the same two filter lines
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. Same FCR alert as seq 25. |
| What did the new screenshot show? | The index is mostly audit_trail events, which never carry a build result. |
| What changed in the tf? | The first filter keeps only lines with `job_duration` and drops `audit_trail`. |
| Does the alert logic change? | No. Same result, less data scanned. |
| Apply to seq 22 and 24 too? | Yes, the same two lines work there. |

## Summary

The screenshot shows `jenkins_statistics` has 14.7 million events and the visible ones are all `audit_trail` fingerprint updates from SYSTEM. Splunk's alert already drops them with `where isnotnull(job_duration)`. The Dynatrace detector now drops them first too, so each run reads far fewer lines and costs less.

## What changed

| Line | Seq 25 | Seq 26 |
|---|---|---|
| First content filter | `filter contains(content, "job_name")` | `filter contains(content, "job_duration")` |
| New filter | None | `filter not contains(content, "audit_trail")` |
| Everything else | Same | Same |

## Event kinds in the index

| Event kind | What it is | Used by the alert? |
|---|---|---|
| audit_trail | Jenkins internal changes, such as fingerprint updates | No |
| jenkins (build) | Build finished, with job_name, job_result and job_duration | Yes |
| jenkins/job_event | Job lifecycle events (queue, stages, trigger) | Only if it has job_duration |
| web_access | Jenkins web access log | No |

## Terraform

Full file: `26-fcr-ng-audit-trail-filter-tf.tf`. Changed lines:

```
fetch logs, from:now()-2h
| filter matchesValue(host.name, "ceaa2099*")
| filter contains(content, "job_duration")
| filter not contains(content, "audit_trail")
| parse content, "JSON:j"
...
```

Resource name stays `fcr_realtime_functional_ng`, so applying it updates the seq 25 detector in place.

## Data flow

```
ceaa2099 Jenkins logs (audit_trail, build, job_event, web_access)
  -> filter: has job_duration, not audit_trail -> build events only
  -> applications* / group-jobs* -> configuration lookup (FCR)
  -> 2+ NG, 0 SUCCESS in 2h -> problem per project (high)
```

## Investigation

| What I checked | What I found |
|---|---|
| Alert screenshots | Identical to seq 25. |
| Raw search | 14,715,642 events; visible ones are audit_trail, source audit_trail, host ceaa2099.prprivmgmt.intraxa. |
| Splunk filter | `where isnotnull(job_duration)` already drops audit_trail. |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 to see how much of the host log is audit_trail. |
| 2 | Run query 2 to confirm build events with job_duration still include applications* and group-jobs*. |
| 3 | `terraform plan` from `26.sh`; expect an in-place update of `fcr_realtime_functional_ng`. |
| 4 | Make the same two-line change in seq 22 and seq 24 when you apply them. |

## Related files

| File | What it is |
|---|---|
| `26-fcr-ng-audit-trail-filter-tf.tf` | FCR detector with the tighter filter |
| `26-fcr-ng-audit-trail-filter-tf-check.dql` | Dynatrace checks |
| `26-fcr-ng-audit-trail-filter-tf.spl` | Splunk checks |
| `26.sh` | Commands |
| `../25-fcr-realtime-functional-ng-tf/` | Previous version |

## Commands

From `26.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/26-fcr-ng-audit-trail-filter-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
