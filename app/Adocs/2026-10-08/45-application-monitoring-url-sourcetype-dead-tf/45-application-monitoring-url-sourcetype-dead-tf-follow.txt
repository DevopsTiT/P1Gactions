# URL Monitoring Sourcetype Dead

## Decision tree

```
Application Monitoring Alert - URL
 Splunk searches sourcetype="text:jenkins"
 index=jenkins_console sourcetypes = jenkins_console (99.8%) + json:jenkins:old
   → text:jenkins missing → Splunk alert matches nothing → dead (silent)
 Dynatrace has no sourcetype filter → would alert where Splunk is silent
   → create detector with enabled = false
   → run check query 1: any "[HTTP Monitor]" lines?
       no  → nothing to monitor → keep disabled or delete
       yes → check query 3: how many jobs NG right now?
              few  → enable (enabled = true)
              many → old silent failures → fix or tune first, then enable
```

## Short takeaway

| Question | Answer |
|---|---|
| What is new? | The jenkins_console index has no `text:jenkins` sourcetype. |
| What does that mean? | The Splunk URL alert has been matching nothing, so it is dead. |
| Why care in Dynatrace? | The detector does not filter on sourcetype, so it could suddenly raise many problems. |
| What changed in the tf? | `enabled = false`, with the same resource name as seq 44. |
| What else did the screenshot confirm? | Host `ceaa2099.prprivmgmt.intraxa` and the console source path format. |

## Summary

The URL alert filters on `sourcetype="text:jenkins"`, but the index only has `jenkins_console` and `json:jenkins:old`. The sourcetype was most likely renamed, and the alert has been silent since. A faithful Dynatrace migration would wake up every URL failure Splunk has been missing. So the detector ships disabled, and you turn it on after the check queries show what it would raise.

## Investigation

| What I checked | What I found |
|---|---|
| Sourcetypes in jenkins_console | `jenkins_console` with 1,009,023 events (99.755%), and `json:jenkins:old` with 2,476 events (0.245%). |
| Sourcetype in the alert | `text:jenkins`, which is not in the list. |
| Host | One value: `ceaa2099.prprivmgmt.intraxa`, which matches the `ceaa2099*` filter. |
| Source format | `job/group-jobs/job/realtime/job/ais/job/ais/8462/console`, which matches the name cleanup. |
| Sample lines | Normal Jenkins console text (git fetch and similar). No `[HTTP Monitor]` lines are in the visible sample. |
| Action | Alert Status Manager, Production, PagerDuty Disable (unchanged from seq 44). |

## Result

| Setting | Value |
|---|---|
| Resource | `application_monitoring_alert_url`, the same as seq 44 |
| enabled | false |
| Query | Unchanged from seq 44 |
| Severity | high |
| pagerduty.enabled | "0" |

### How to switch it on

| Step | What to do |
|---|---|
| 1 | Run Splunk query 3 (`"[HTTP Monitor]" \| stats count by sourcetype`) to see whether HTTP Monitor lines exist at all. |
| 2 | Run Splunk query 6 (scheduler log) to confirm the alert has been returning 0 results. |
| 3 | Run Dynatrace check query 3 to see what would be raised right now. |
| 4 | If the list is short and real, set `enabled = true` and apply. |
| 5 | Tell the Splunk owner: if they want to keep the Splunk alert during the migration, change its sourcetype to `jenkins_console`. |

## Data flow map

```
Splunk: jenkins_console index ──(sourcetype=text:jenkins)──► 0 events ► alert never fires
Dynatrace: Jenkins console logs (ceaa2099) → "[HTTP Monitor]" → status code
  → per job: fails >= 2, oks == 0 → problem      [detector disabled until checked]
```

## Related files

| File | What it is |
|---|---|
| `45-application-monitoring-url-sourcetype-dead-tf.tf` | The detector, disabled |
| `45-application-monitoring-url-sourcetype-dead-tf-check.dql` | Line existence, runs per job, and what would fire now |
| `45-application-monitoring-url-sourcetype-dead-tf.spl` | Sourcetype proof and the scheduler result count |
| `45.sh` | Commands |

## Commands

These are in `45.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/45-application-monitoring-url-sourcetype-dead-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
