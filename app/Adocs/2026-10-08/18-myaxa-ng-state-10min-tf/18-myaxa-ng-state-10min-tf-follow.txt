# MyAXA NG State For 10min TF

## Decision tree

```
MyAXA External Check (Login_Check or Function_Check)
  NG run older than 10 minutes in the last hour?
    no  -> no problem
    yes -> is there a newer run, with the same NG result?
             no (newer run is SUCCESS or a different result) -> no problem
             yes -> MyAXA in a maintenance window right now?
                      yes -> no problem
                      no  -> problem per JobName (medium, pagerduty 0)
Detector never fires?
  -> check.dql query 1: job_name values / host
  -> query 2: maintenance_window lookup format
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the alert catch? | A MyAXA external check that has stayed NG for 10 minutes or more. |
| Which checks? | Login_Check (MyAXA login-check job) and Function_Check (MyAXA job). |
| Identity | `JobName`, so one problem per check. |
| Maintenance | Skipped when maintenance_window has an active MyAXA row. |
| Severity | medium (Splunk priority Normal). |
| PagerDuty | "0" (email only). |
| What replaces MYAXA_Monitoring.csv? | The newest Jenkins log line for the job. |

## Summary

Splunk takes the newest NG run that is at least 10 minutes old, compares it with the "current" result stored in `MYAXA_Monitoring.csv`, and alerts if the result is the same and the current run is newer. Dynatrace does the same in one query: it reads both the old NG run and the newest run from the Jenkins logs for the last hour, compares them per check, and drops the row if MyAXA is in a maintenance window.

## Splunk to Dynatrace mapping

| Splunk piece | What it means | Dynatrace |
|---|---|---|
| `index=jenkins` | Jenkins job results | `matchesValue(host.name, "ceaa2099*")`, `parse content, "JSON:j"` |
| `job_name=".../External%20Check%20-%20MyAXA%20login-check/"` | MyAXA login check job | `JobName = "Login_Check"` |
| `job_name=".../External%20Check%20-%20MyAXA/"` | MyAXA function check job | `JobName = "Function_Check"` |
| `latest=-10m job_result!="SUCCESS" \| head 1` | Newest NG run that is at least 10 minutes old | `ng_old_result` and `ng_old_time` only for rows older than 10 minutes, then the last one |
| `inputlookup MYAXA_Monitoring.csv` | Current result, saved by another search | `takeLast(job_result)` and `max(timestamp)` for the job |
| `Time_10min_ago != Current_Time` | The current run is a newer run | `Current_Time > Time_10min_ago` |
| `Job_Result_10min_ago == Current_Job_Result` | Still the same NG result | Same comparison |
| `maintenance_window.csv`, application MyAXA, now between start and end | Don't alert during maintenance | Lookup with `start_ts < now() and end_ts > now()`, then `isNull(mw.start_ts)` |
| Last 60 minutes, cron */5 | Look back one hour every 5 minutes | `from:now()-60m`; detector runs every minute |
| Results > 0, Once | Any row sends one email | Each row is a problem; identity `JobName` |
| Email, priority Normal | Email only | severity medium, pagerduty "0" (recipients not copied) |

## Terraform

Full file: `18-myaxa-ng-state-10min-tf.tf`. Key query:

```
fetch logs, from:now()-60m
| filter matchesValue(host.name, "ceaa2099*")
| filter contains(content, "MyAXA", caseSensitive:false)
| parse content, "JSON:j"
| fieldsAdd job_name, job_result, JobName (Login_Check or Function_Check)
| sort timestamp asc
| fieldsAdd ng_old_result, ng_old_time (only NG rows older than 10 minutes)
| summarize Job_Result_10min_ago, Time_10min_ago, Current_Job_Result, Current_Time, by:{ JobName }
| filter Current_Time > Time_10min_ago and Current_Job_Result == Job_Result_10min_ago
| lookup maintenance_window (MyAXA, active now)
| filter isNull(mw.start_ts)
```

## Data flow

```
Jenkins External Check jobs (MyAXA login-check, MyAXA)
  -> Jenkins host ceaa2099 log -> Dynatrace Grail
  -> Records detector (every minute, last 60 min)
       old NG run (10+ min ago)  vs  newest run
       + maintenance_window lookup
  -> same NG and not in maintenance -> problem per JobName (medium, app MyAXA)
  -> workflow -> email
```

## Investigation

| What I checked | What I found |
|---|---|
| Two subsearches | Login_Check and Function_Check, each the newest NG run older than 10 minutes (`latest=-10m`, `head 1`). |
| Current state | Comes from `MYAXA_Monitoring.csv`, which another Splunk search must write. The `.spl` file finds it. |
| Condition | Same result as 10+ minutes ago, and a newer run exists. |
| Maintenance | Outer join to maintenance_window.csv; only `maintenance = "No"` alerts. |
| Schedule | cron */5, Last 60 minutes, results > 0, Once, no throttle. |
| Action | Email, priority Normal, subject `Splunk Alert: $name$`. |
| Jenkins host | Reused ceaa2099 from the seq 11 and 12 Jenkins alerts. |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1. The two `job_name` values must match the tf exactly. |
| 2 | Run query 2. Upload `/lookups/maintenance_window` if missing; adjust the timestamp parse if start and end are not `yyyy/MM/dd HH:mm`. |
| 3 | Run query 3 to see past NG streaks and estimate how often it will fire. |
| 4 | `terraform plan` and `terraform apply` from `18.sh`. |
| 5 | Once Dynatrace is live, the Splunk search that writes `MYAXA_Monitoring.csv` can be retired too. |

## Related files

| File | What it is |
|---|---|
| `18-myaxa-ng-state-10min-tf.tf` | The detector |
| `18-myaxa-ng-state-10min-tf-check.dql` | Dynatrace checks |
| `18-myaxa-ng-state-10min-tf.spl` | Splunk checks, including who writes MYAXA_Monitoring.csv |
| `18.sh` | Commands |

## Commands

From `18.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/18-myaxa-ng-state-10min-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
