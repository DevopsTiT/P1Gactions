# Cockpit360 Real Time And Functional NG TF

## Decision tree

```
jenkins_statistics build event (ceaa2099, json:jenkins:old)
  job_name applications* or group-jobs*, and job_duration present?
    no  -> ignored
    yes -> group-jobs = Real Time, applications = Functional
           Real Time name from "Building applications » x » y" -> applications/x/y
           -> configuration lookup: application == "Cockpit360"?
                yes -> Real Time 2+ non-SUCCESS and 0 SUCCESS in 2 hours?
                         yes -> problem per project (high)
                         next SUCCESS -> closes
PagerDuty?
  -> setting is cut off in the screenshot; check it and set pagerduty.enabled
```

## Short takeaway

| Question | Answer |
|---|---|
| Template | Same Real Time and Functional NG logic as AG Portal NTTGW and Banca Portal. |
| Data source | `index=jenkins_statistics`, sourcetype `json:jenkins:old` (not `jenkins/test`). |
| Real Time job | `group-jobs*`. Its name comes from the "Building ..." text. |
| Functional job | `applications*`. |
| Application | "Cockpit360". |
| Window | 2 hours, cron every minute. |
| Severity | high. |
| PagerDuty | Set to "0" for now. The setting is below the visible part of the screenshot. |

## Summary

Cockpit360 ALL uses the same NG logic as seq 19 and 20, but on the `jenkins_statistics` data, where Real Time jobs are `group-jobs*` and Functional jobs are `applications*`. A group job's log says "Building applications » x » y", so the detector turns that into `applications/x/y` to match the Functional job, then keeps only Cockpit360 projects.

## Differences from seq 19 and 20

| Setting | AG Portal NTTGW / Banca Portal | Cockpit360 ALL |
|---|---|---|
| Index | jenkins, source jenkins/test | jenkins_statistics, sourcetype json:jenkins:old |
| Real Time job | App-Ops-OpenOps/app-check-group/Real Time Check | group-jobs* |
| Functional job | App-Ops-OpenOps/app-check-jobs/Functional/ | applications* |
| Project name | Rename Real Time path to Functional path | `tempname` from "Building ..." with " » " turned into "/" |
| ABORTED and FAILURE | Excluded | Not excluded (only `isnotnull(job_duration)`) |
| Remarks | None | "OKメンテナンス中" kept as `remarks` |
| Final search | event=2 or recovery | event > 0 or recovery |

## Terraform

Full file: `22-cockpit360-realtime-functional-ng-tf.tf`. Query:

```
fetch logs, from:now()-2h
| filter matchesValue(host.name, "ceaa2099*")
| filter contains(content, "job_name")
| parse content, "JSON:j"
| fieldsAdd job_name, job_result, job_duration
| filter matchesValue(job_name, "applications*") or matchesValue(job_name, "group-jobs*")
| filter isNotNull(job_duration)
| parse content, "LD '\"name\":\"Building ' LD:tempname '\"'"
| fieldsAdd is_realtime, name, remark
| lookup /lookups/jenkins/configuration -> application
| filter cfg.application == "Cockpit360"
| summarize rt_fails, rt_oks, functional_runs, remarks, last_seen, by:{ application, name }
| filter rt_fails >= 2 and rt_oks == 0
```

## Data flow

```
Jenkins group-jobs (Real Time) + applications (Functional)
  -> json:jenkins:old events on ceaa2099 -> Grail
  -> Records detector (every minute, last 2 hours) + configuration lookup (Cockpit360)
  -> 2+ NG, 0 SUCCESS -> problem per project (high) -> workflow -> email (PagerDuty if enabled)
  -> next SUCCESS -> closes
```

## Investigation

| What I checked | What I found |
|---|---|
| Base search | jenkins_statistics, json:jenkins:old, applications* or group-jobs*, job_duration present. |
| Screenshot 3 | 1,009,723 events; sources audit_trail (81%), jenkins (15%), jenkins/job_event (3.6%), web_access. Host ceaa2099.prprivmgmt.intraxa. |
| Real Time vs Functional | job_result emptied for applications/ (Functional); job_duration emptied for group-jobs (Real Time). |
| Name pairing | `rex "name":"Building <tempname>"`, then " » " to "/". |
| Schedule | cron */1, Last 2 hours. |
| Action | Alert Status Manager, Production. PagerDuty line not visible. |

## Result

| Step | What to do |
|---|---|
| 1 | Scroll down in the Splunk alert. If PagerDuty is Enable, change `pagerduty.enabled` to "1". |
| 2 | Run check.dql query 2. `tempname` must fill for group-jobs runs. |
| 3 | Run query 3 to confirm Cockpit360 rows exist in configuration. |
| 4 | `terraform plan` and `terraform apply` from `22.sh`. |

## Related files

| File | What it is |
|---|---|
| `22-cockpit360-realtime-functional-ng-tf.tf` | The detector |
| `22-cockpit360-realtime-functional-ng-tf-check.dql` | Dynatrace checks |
| `22-cockpit360-realtime-functional-ng-tf.spl` | Splunk checks, including the alert's action settings |
| `22.sh` | Commands |
| `../12-jenkins-function-monitor-alert-tf/` | Generic function alert on the same data |
| `../19-ag-portal-nttgw-realtime-functional-ng-tf/` | Same NG template on jenkins/test |

## Commands

From `22.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/22-cockpit360-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
