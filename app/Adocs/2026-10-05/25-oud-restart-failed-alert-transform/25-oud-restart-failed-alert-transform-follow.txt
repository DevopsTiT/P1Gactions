# OUD Restart Failed Alert Transform

## Decision tree

```
Splunk "OUD restart failed": index=ods sourcetype=oud_service failed
 Step 1: where are the OUD logs in Dynatrace?   → check.dql query 1 → note log.source, host, bucket
   no rows?                                     → OUD log file not ingested → add it to OneAgent log monitoring first
 Step 2: alert shape
   Splunk checks once a day at 04:01 over 24 h  → a failure at 04:05 waits ~24 h to be seen
   Dynatrace detector                           → alerts within minutes, any time of day (recommended)
   must stay "once a day"?                      → scheduled workflow at 04:01 instead (Option B)
 Step 3: "failed" match
   Splunk term search, case-insensitive         → matchesPhrase(content, "failed") (word match, ignores case)
 Step 4: routing (High + PagerDuty)
   logs come from a OneAgent host?              → dt.source_entity = host → AGO tags → standard SILVA + PagerDuty flow works
   no host entity?                              → same routing gap as the Cisco alert (seq 21)
 Step 5: email                                  → email workflow (recipients collapsed in the screenshot → placeholder)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it watch? | The OUD (Oracle Unified Directory) service log for the word "failed", meaning a service restart failed |
| Splunk timing | Once a day at 04:01, looking back 24 hours |
| Dynatrace shape | Detector that checks every minute, plus an email workflow |
| Big improvement | A failure is seen in minutes, not up to a day later |
| Paging | Standard SILVA and PagerDuty workflow. Works well if the problem is attached to the OUD host |
| Files | `main.tf` (real), `house-style.tf` (repo layout), `check.dql` |

## Summary

The Splunk alert runs once a day at 04:01 and fires if the OUD service log said "failed" in the last 24 hours. That's probably timed just after a nightly restart, but it also means a failure at any other time waits almost a day. In Dynatrace, a detector checks every minute and opens a High problem as soon as the line appears. If the OUD log comes from a host running OneAgent, the problem can be attached to that host, so the host's AGO tags let your standard workflow create the SILVA ticket and page PagerDuty without extra routing work.

## What the Splunk alert does

| Part | Value | What it means |
|---|---|---|
| Name | OUD restart failed | OUD is Oracle Unified Directory, an LDAP directory server |
| Search | `index=ods sourcetype=oud_service failed` | OUD service log lines containing the word "failed" |
| Schedule | Cron `1 4 * * *` | Every day at 04:01 |
| Time range | Last 24 hours | Looks back one full day |
| Trigger | More than 0 results, once | Any failed line fires one alert |
| Throttle | Off | Runs once a day anyway |
| Actions | Triggered alert High, PagerDuty, email | Pages and emails |

## Splunk to Dynatrace mapping

| Splunk | Dynatrace |
|---|---|
| `index=ods` | Bucket or log source found by `check.dql` query 1 |
| `sourcetype=oud_service` | `matchesValue(log.source, "*oud_service*")` (placeholder; replace with the real value) |
| `failed` (term, any case) | `matchesPhrase(content, "failed")`: matches the word, ignores case |
| Daily 04:01 over 24 hours | Detector every minute, sliding window 5 |
| More than 0 | Threshold 0, Above |
| High | `alert.severity = high` |
| PagerDuty | Standard SILVA and PagerDuty workflow |
| Email | Email workflow |

`matchesPhrase` is closer to Splunk than `contains`: it ignores case, and it matches "failed" as a word, so text like `failedCount=0` does not match.

## Step 1: find the logs

```dql
fetch logs, from:now()-7d
| filter contains(log.source, "oud", caseSensitive: false) or contains(content, "oud", caseSensitive: false)
| summarize lines = count(), by:{ dt.system.bucket, log.source, host.name, dt.entity.host }
| sort lines desc
| limit 30
```

| Result | Next step |
|---|---|
| Rows with a `log.source` like `/.../oud_service.log` | Put that value in the detector filter |
| `dt.entity.host` is filled | Good: the problem can be attached to the host (routing works) |
| No rows | The OUD log isn't ingested. Add the file to OneAgent log monitoring (or the forwarder) first |

## Detector query

```dql
fetch logs
| filter matchesValue(log.source, "*oud_service*")
| filter matchesPhrase(content, "failed")
| makeTimeseries count = count(default: 0), by:{ dt.entity.host }, interval:1m
```

| Setting | Value |
|---|---|
| Threshold | 0, Above |
| Sliding window | 5 |
| Violating samples | 1 |
| Dealerting samples | 5 |
| alert.severity | high |
| dt.source_entity | `{dims:dt.entity.host}` (attaches the problem to the OUD host) |

Splitting by `dt.entity.host` gives one series per OUD server, so a failure on server 2 is reported on server 2. Check in the Anomaly Detection UI that the `{dims:dt.entity.host}` placeholder fills in on a test run; if it doesn't, remove the `dt.source_entity` property and use a routing option from seq 21.

## Option B: keep the once-a-day check

If the team really wants one check per day (for example, only the 04:00 restart matters):

| Part | Value |
|---|---|
| Trigger | Schedule `1 4 * * *`, `time_zone = "Asia/Tokyo"` |
| Task 1 | DQL count of "failed" lines in the last 24 hours |
| Task 2 | Only if count > 0: run-javascript `createEvent` with CUSTOM_ALERT, so a problem opens and the standard workflow pages |
| Task 3 | Email with the lines |

The detector is still the better choice: same signal, found faster, and no JavaScript step.

## Questions for the OUD team

| Question | Why it matters |
|---|---|
| Does OUD restart on a schedule (around 04:00)? | Confirms why Splunk ran at 04:01 |
| Was Splunk running in UTC or JST? | `1 4 * * *` in UTC is 13:01 JST |
| Who gets the email? | Recipients are collapsed in the screenshot |
| Are there harmless lines with "failed"? | `check.dql` query 3 lists them; exclude them if needed |

## Data flow

```
OUD host (oud_service log)
  → OneAgent log monitoring → Grail
  → detector every minute: "failed" count > 0 per host, window 5
  → problem "Prod_OUD_RestartFailed_High" on the OUD host (high)
  → standard flow: host AGO tags → SILVA incident + PagerDuty
  → email workflow → OUD owners with the failed lines
  → 5 clean minutes → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot | `index=ods sourcetype=oud_service failed`, cron `1 4 * * *`, last 24 hours, > 0, once, no throttle |
| Actions | Triggered alert High, PagerDuty, Send email (recipients collapsed) |
| Description | Empty ("Optional") |
| Routing | If logs come from a OneAgent host, the problem can carry host AGO tags |

## Result

Use a detector on the OUD service log with `matchesPhrase(content, "failed")`, split by host and attached to the host, plus an email workflow. Find the real `log.source` first with `check.dql` query 1, and fill in the recipients.

## Related files

| File | Purpose |
|---|---|
| `25-oud-restart-failed-alert-transform-main.tf` | Detector and email workflow |
| `25-oud-restart-failed-alert-transform-house-style.tf` | Same alert in the repo's `dynatrace_log_alert` layout |
| `25-oud-restart-failed-alert-transform-check.dql` | Find logs, past failures, noise check |
| `25.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/21-cisco-vpn-ldap-two-alerts-transform/` | Routing gap options for alerts without a host |

## Commands

See `25.sh` (not run).
