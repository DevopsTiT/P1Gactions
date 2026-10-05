# Broker Policy Undefined Error Alert

## Decision Tree

```
22 screenshots arrive
 Alert name already in seq 34? (URL, URL for MyAXA, function, function for AG Portal,
                                 BancaPotal, Compass, Compass PB)
   yes → no change, seq 34 detectors already cover them
 New alert: ALJ Broker Policy Maintenance: Cannot read properties of undefined
   Is it "count per minute > N"? → yes → static-threshold detector (no workflow)
   Logs found by k8s.namespace.name? (check.dql query 1)
     yes → apply as is
     no  → change the first filter line to the real attribute
   Fires too often in query 2 and 3? → raise threshold or require 2 of 5 minutes
```

## Short Takeaway

| Question | Answer |
|---|---|
| How many new alerts? | One. The other 21 screenshots are seq 34 alerts that are already converted |
| What does it watch? | The JavaScript error "Cannot read properties of undefined" in the broker policy maintenance app |
| When does it fire? | More than 50 of those errors in any one minute |
| Dynatrace shape | One static-threshold detector, threshold 50, 1-minute buckets |
| Workflow needed? | No |
| Biggest Splunk problem | Every bad minute could send up to 5 emails, because the search runs every minute over 5 minutes with no throttle |

## Summary

The Broker Policy alert is a plain "errors per minute above 50" rule, so a single Dynatrace detector replaces it. Dynatrace opens one problem and keeps it open while errors stay high, which removes the repeated emails Splunk sent. The seven Application Monitoring alerts in this batch match seq 34 exactly, so no new Terraform is needed for them.

## What the Splunk Alert Does

| Setting | Value | What it means |
|---|---|---|
| Search | `index=brokerpolicymaintenance-prod-axa-li-jp *Cannot read properties of undefined*` | Finds the JavaScript TypeError in the app logs |
| Grouping | `timechart span=1m count` | Counts errors per minute |
| Condition | `where count > 50` | Keeps only minutes with more than 50 errors |
| Time range | Last 5 minutes | Looks back 5 minutes each run |
| Schedule | `*/1 * * * *` | Runs every minute |
| Trigger | Results > 0, For each result | One email per bad minute found |
| Throttle | Off | Nothing stops repeat emails |
| Description | Need to check the OCP POD Status | The runbook hint: look at the OpenShift pods |
| Action | Email, Normal priority, subject `Splunk Alert: $name$` | Sent to one person and the infra MWSS list |

## Why the Error Matters (Beginner View)

| Concept | What it means | Why you care |
|---|---|---|
| `Cannot read properties of undefined` | Node.js code tried to read a field from something that does not exist | Usually a bug, or a backend returned empty data |
| OCP | OpenShift Container Platform, Red Hat's Kubernetes | The app runs as pods there |
| Pod | One running copy of the app container | A crashing or unready pod often causes a burst of these errors |
| 50 per minute | The noise floor the team chose | A few errors are normal; a burst means something broke |

## Splunk Problems Found

| Problem | What it means |
|---|---|
| Overlapping windows | Each bad minute stays inside the 5-minute window for 5 runs, so it can be emailed 5 times |
| For each result | A 3-minute burst gives 3 emails per run |
| No throttle | Combined, a 5-minute burst can send about 15 emails |
| Personal recipient | One named person receives every alert; better to route by team |

## Dynatrace Detector

File: `36-broker-policy-undefined-error-alert.tf`

```
fetch logs
| filter k8s.namespace.name == "brokerpolicymaintenance-prod-axa-li-jp"
| filter contains(content, "Cannot read properties of undefined", caseSensitive: false)
| makeTimeseries count = count(default: 0), interval:1m
```

| Setting | Value | Why |
|---|---|---|
| Analyzer | Static threshold | The Splunk rule is a fixed number |
| threshold | 50 | Same as Splunk |
| alertCondition | ABOVE | Same as `count > 50` |
| violatingSamples | 1 | One bad minute is enough, like Splunk |
| slidingWindow | 5 | Matches the 5-minute look-back |
| dealertingSamples | 5 | Closes after 5 quiet minutes, so a flapping burst stays one problem |
| alert.severity | medium | Splunk priority was Normal |
| app.name | Broker Policy Maintenance | Lets the standard flow route an entity-less log problem |
| Title | `Prod_BrokerPolicyMaintenance_UndefinedPropertyError_Normal` | `_Normal` suffix: email, no page unless the flow says otherwise |

## Screenshots Already Covered by Seq 34

| Splunk alert | Seq 34 detector | Change needed? |
|---|---|---|
| Application Monitoring Alert - URL | `jenkins_url_check_failed` | No |
| Application Monitoring Alert - URL for MyAXA | `jenkins_url_check_failed` | No |
| Application Monitoring Alert - function | `jenkins_functional_check_failed` | No |
| function for AG Portal (AG Portal NTTGW) | `jenkins_functional_check_failed` | No |
| function for BancaPotal (Banca Portal) | `jenkins_functional_check_failed` | No |
| function for Compass (extra メンテナンス中 rex) | `jenkins_functional_check_failed` | No |
| function for Compass PB (Compass AG) | `jenkins_functional_check_failed` | No |

The PagerDuty keys visible in these screenshots were not copied anywhere.

## Data Flow

```
OCP pods (brokerpolicymaintenance-prod-axa-li-jp)
  → container logs → Dynatrace Grail (fetch logs)
  → detector: count errors per minute
  → minute > 50 ? → open problem (one, not many)
  → standard flow (app.name, severity medium) → SILVA / email
  → 5 quiet minutes → problem closes
```

## Investigation

| Checked | Evidence |
|---|---|
| Alert names in this batch versus seq 34 | Seven Application Monitoring names all listed in seq 34 tables |
| Searches in the repeat screenshots | Same SPL as seq 34, including `check_maintenance_window` and `add_alert_info` |
| Broker alert in earlier seqs | Not found in seq 27 to 35 |
| Index naming | Matches the `<app>-prod-axa-li-jp` OCP namespace pattern seen for Compass in seq 32 |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 to confirm the namespace attribute |
| 2 | Run queries 2 and 3 to see how often more than 50 per minute happened in 7 days |
| 3 | Ask the owner whether the personal recipient should stay |
| 4 | `terraform plan` should show 1 detector to add |
| 5 | Disable the Splunk alert after Dynatrace has run in parallel for a few days |

## Related Files

| File | Purpose |
|---|---|
| `36-broker-policy-undefined-error-alert.tf` | Detector Terraform |
| `36-broker-policy-undefined-error-alert-check.dql` | Four check queries |
| `36.sh` | Commands |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Evidence |
| `2-result.md` | Next steps |
| `3-glossary.md` | Terms |

## Commands

See `36.sh`.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/36-broker-policy-undefined-error-alert"
terraform init
terraform validate
terraform plan
```
