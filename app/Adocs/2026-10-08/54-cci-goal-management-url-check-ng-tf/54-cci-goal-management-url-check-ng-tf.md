# CCI Goal Management URL Check

## Decision tree

```
Prod_Life_CCIGoalManagement_URLCheck_NG
 index=jenkins source="jenkins/test" + URL template (made for jenkins_console)?
   → yes → template does not fit this data
 name = replace(source, ...) → source is always "jenkins/test" → every job becomes "jenkins/test"
 lookup on "jenkins/test" → no match → application "-"
 build_report has "status"? → no (check.dql 2) → Response_Code empty → status always "NG"
 → Splunk: one row, NG forever, no recovery → effectively broken
 rebuild in Dynatrace on job_result (SUCCESS / not) per job_name containing "management"
   → fails >= 2 and oks == 0 in 60m → problem (high, pagerduty 0)
   → enabled = false until check.dql 1 shows the expected jobs
```

## Short takeaway

| Question | Answer |
|---|---|
| What is it meant to watch? | The CCI Goal Management URL check job in Jenkins. |
| Does it work in Splunk? | No. It is stuck on NG for a single fake row called "jenkins/test". |
| Why? | The URL template expects `jenkins_console` source paths and a `status` field. `jenkins/test` build_report events have neither. |
| What does the tf do? | Uses `job_result` per job: 2 or more non-SUCCESS results in 60 minutes and no SUCCESS opens a problem. |
| enabled | false, until you confirm which jobs match "management" |
| Severity and PagerDuty | high (Alert Status Manager, Production) and "0" (PagerDuty Disable) |

## Summary

This alert copies the `jenkins_console` URL template onto `index=jenkins source=jenkins/test` data, which doesn't fit. Every job collapses into one row named "jenkins/test", the response code is always empty, and the status is permanently NG. The Dynatrace detector rebuilds the intent on what the data actually has: each build's `job_result`. Because this is new logic rather than a copy, it ships disabled until check query 1 shows the expected jobs.

## Investigation

### Step by step: why the Splunk search is broken

| Splunk step | What happens on jenkins/test data |
|---|---|
| `job_name="*Management*"` | Matches jobs with "management" anywhere in the name. Splunk wildcards ignore case, so this can include other apps. |
| `name=replace(source,"job/","")` and the other replaces | `source` is always `jenkins/test`, so `name` becomes "jenkins/test" for every job. |
| `rename status as responsecode` | build_report events have no `status` field (the field list in your earlier search screenshot shows none), so `responsecode` is empty. |
| `lookup configuration job_name as name` | "jenkins/test" is not a job name, so `application` is "-". There is no `where isnotnull(job_name)` to drop it. |
| `streamstats ... by name` and `index<=2` | Keeps the last 2 events of all matching jobs combined, not per job. |
| `status=if(Response_Code="200","OK","NG")` | Response_Code is empty, so status is always NG. |
| `search status="NG" OR ...` | Always passes, so there is one result every minute, forever. |

### What this means on-call

| Effect | Why it matters |
|---|---|
| A permanent NG row named "jenkins/test" | Alert Status Manager probably sent one NG long ago and then nothing. Nobody is really watching this check. |
| A real CCI Goal Management failure changes nothing | The alert can't tell OK from NG for the actual job. |

Splunk lines 3 and 4 in the `.spl` file prove this. If every scheduled run returns `result_count` 1, the search is stuck.

### Other settings

| Setting | Value |
|---|---|
| Time range | Last 24 hours |
| Cron | `*/1` |
| Trigger | Results > 0, once, for each result, no throttle |
| Actions | Add to Triggered Alerts, plus Alert Status Manager with Production email |
| PagerDuty | Disable. A URL was visible, and I did not copy it. |

## Result

| Setting | Value |
|---|---|
| Resource | `cci_goal_management_url_check_ng` |
| enabled | false |
| Window | `from:now()-60m` (Splunk's "last 2 runs" in a bounded window) |
| Filter | `contains(lower(job_name), "management")`, `job_result != "ABORTED"` |
| Opens when | `fails >= 2 and oks == 0` |
| Identity | job_name |
| Severity | high |
| pagerduty.enabled | "0" |

### Before enabling

| Step | What to do |
|---|---|
| Run check query 1 | If jobs other than CCI Goal Management match, narrow the filter, for example `contains(lower(job_name), "goal")` or the exact job name. |
| Run check query 3 | If a job runs less than twice in 60 minutes, widen the window. |
| Set enabled to true | Then apply. |

## Data flow map

```
Splunk (broken):
  jenkins/test events → name = "jenkins/test" (all jobs) → no status → status NG forever
Dynatrace (rebuilt, disabled):
  Jenkins (ceaa2099) build_report JSON
  → job_name contains "management", drop ABORTED
  → lookup configuration (application, info only)
  → per job_name in 60m: fails >= 2 and oks == 0
  → problem (high, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `54-cci-goal-management-url-check-ng-tf.tf` | Rebuilt detector, disabled |
| `54-cci-goal-management-url-check-ng-tf-check.dql` | Matching jobs, status field check, runs per hour |
| `54-cci-goal-management-url-check-ng-tf.spl` | Matching jobs, status field check, scheduler and audit history |
| `54.sh` | Commands |

## Commands

These are in `54.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/54-cci-goal-management-url-check-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
