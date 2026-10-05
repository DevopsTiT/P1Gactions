# Cisco VPN LDAP Alert To Dynatrace

## Decision tree

```
Move "Cisco VPN : LDAP Connections are failing" from Splunk to Dynatrace
 Step 1: are the ASA syslog lines in Grail?
   discovery DQL finds "Windows_LDAP as FAILED"?  → yes, note bucket and field names
   no rows?                                         → network syslog not ingested yet; fix ingest first
 Step 2: build the alert (count > 3 in 1 minute)
   simple and fast to set up?                       → Option A: Anomaly Detection on DQL (recommended)
   high volume, worried about query cost?           → Option B: OpenPipeline log metric + metric alert
 Step 3: route it
   ASA is not a monitored host, so no AGO tags      → decide SILVA group (network team) and set it in the event or workflow
   needs PagerDuty critical?                        → map in the workflow (default is warning for non-infrastructure)
 Step 4: test
   send a test syslog line 4 times in 1 minute      → problem opens → SILVA + PD
```

## Short takeaway

| Splunk setting | Dynatrace equivalent |
|---|---|
| Search `index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*` | `fetch logs` filtered on the networksyslog bucket and `contains(content, "Windows_LDAP as FAILED")` |
| Cron `*/1 * * * *`, last 1 minute | `makeTimeseries ... interval:1m`, sliding window 1 |
| Number of results greater than 3 | Static threshold 3, condition Above |
| Trigger once | One problem stays open while it keeps breaching (no repeat alerts) |
| Severity Critical | `event.type` CUSTOM_ALERT plus a severity property for PagerDuty |
| PagerDuty action | Your OPEN workflow (PagerDuty trigger task) |
| Send email action | Workflow email task or a problem notification |

## Summary

The Splunk alert counts ASA syslog lines that say an LDAP server in group `Windows_LDAP` was marked **FAILED**, every minute, and fires when there are more than 3. In Dynatrace this becomes an **Anomaly Detection custom alert**: a DQL query turns those log lines into a per-minute count, and Dynatrace opens a problem when the count goes above 3. The problem then flows through your existing SILVA and PagerDuty workflow.

## What the Splunk alert does

| Part | Value | What it means |
|---|---|---|
| Name | Cisco VPN : LDAP Connections are failing which will impact end users using windows basic | Title shown to responders |
| Search | `index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*` | Cisco ASA firewall logs where the LDAP server group `Windows_LDAP` was marked FAILED |
| Schedule | Cron `*/1 * * * *` | Runs every minute |
| Time range | Last 1 minute | Looks at the last minute only |
| Trigger | Number of results greater than 3 | More than 3 failure lines in that minute |
| Trigger mode | Once | One alert per run that breaches |
| Throttle | Off | It can alert again the next minute |
| Severity | Critical | Highest severity |
| Actions | PagerDuty and email | Who gets told |

The ASA message behind this is usually **ASA-2-113022**: `AAA Marking LDAP server <ip> in aaa-server group Windows_LDAP as FAILED`. It means the VPN can't reach the AD/LDAP server, so users logging in with Windows credentials can't connect.

## Step 1 — find the logs in Dynatrace

```dql
fetch logs, from:-24h
| filter contains(content, "Windows_LDAP as FAILED")
| fields timestamp, dt.system.bucket, log.source, host.name, content
| sort timestamp desc
| limit 20
```

| Result | Next step |
|---|---|
| Rows come back | Note the bucket name and which field identifies the ASA (often `log.source`, `host.name` or a copied `sourcetype`) |
| No rows in 24 hours | Widen to `from:-30d`; if still empty, confirm the network syslog is sent to Dynatrace at all |

If you can't find any real failure lines, check that the ASA logs arrive at all:

```dql
fetch logs, from:-1h
| filter contains(content, "%ASA-")
| summarize count = count(), by:{dt.system.bucket, log.source}
```

## Option A — Anomaly Detection custom alert (recommended)

Where: **Anomaly Detection app → Custom alerts → New → Static threshold**.

Query (swap the bucket filter for whatever Step 1 showed):

```dql
fetch logs
| filter dt.system.bucket == "networksyslog"
| filter contains(content, "Windows_LDAP as FAILED")
| makeTimeseries count = count(default: 0), interval:1m
```

If your logs keep the Splunk sourcetype as a field, add `| filter sourcetype == "cisco:asa"` after the bucket line.

| Setting | Value | Splunk equivalent |
|---|---|---|
| Threshold | 3 | "is greater than 3" |
| Alert condition | Above | "greater than" |
| Violating samples | 1 | Fire on the first bad minute |
| Sliding window | 1 | Last 1 minute |
| Dealerting samples | 5 | Close after 5 clean minutes (Splunk has no close) |
| Alert on missing data | Off | A quiet minute is good, not missing |
| event.type | CUSTOM_ALERT | Opens a problem |
| event.name | Cisco VPN : LDAP Connections are failing which will impact end users using windows basic | Same title |
| event.description | More than 3 "Windows_LDAP as FAILED" messages in 1 minute from Cisco ASA (networksyslog) | Description box |
| alert.severity | critical | Severity Critical |

`count(default: 0)` makes quiet minutes show 0 instead of a gap, so the alert closes cleanly.

Example settings JSON: `3-cisco-vpn-ldap-alert-to-dynatrace-anomaly-detector.json`. Check it against your tenant's schema before importing.

## Option B — log metric plus metric alert (cheaper at high volume)

Option A runs a log query every minute. If networksyslog is very large, that costs query credits. Instead, count the lines once as they arrive:

| Step | Where | Setting |
|---|---|---|
| 1 | OpenPipeline → Logs → the networksyslog pipeline → Metric extraction | Counter metric `log.cisco.vpn.ldap_failed`, matching `contains(content, "Windows_LDAP as FAILED")` |
| 2 | Anomaly Detection → Custom alert | Query `timeseries count = sum(log.cisco.vpn.ldap_failed, default: 0), interval:1m` with the same threshold settings as Option A |

The metric only counts from the moment you create it; it does not backfill history.

## Step 3 — routing to SILVA and PagerDuty

This is the part that is different from the Windows VM alert.

| Issue | Why | What to do |
|---|---|---|
| No AGO tags on the problem | The ASA is not a OneAgent host, so there is no host entity with `AGO_AXA_SUPPORTGROUP` or `AGO_AXAENVIRONMENTNAME` | Agree the SILVA team (network or VPN support) and either add a rule in the OPEN workflow that matches this `event.name`, or create a custom device entity for the ASA with the AGO tags |
| Without a group the ticket goes to the default team | The workflow falls back when no group tag is found | Fix the line above before going live |
| PagerDuty severity will be `warning` | The workflow sends `error` only when impact is Infrastructure | Make the PD task read `alert.severity` (critical) or match this event name |
| Email action | Splunk sends email directly | Add an email task to the workflow, or a problem notification for this alert |
| Splunk "Expires 24 hours" | Keeps the triggered alert in the Splunk list | Not needed; problems stay in history |

## Step 4 — test

The real message comes from the ASA, so test with care:

| Method | How |
|---|---|
| Safest | Temporarily set the threshold to 0, wait for one real failure line, confirm, then set it back to 3 |
| Synthetic line | Send 4 test syslog lines containing `Windows_LDAP as FAILED` to the syslog collector within one minute (command in `3.sh`, run from a host allowed to send syslog) |
| Check | Problems app shows the new title; OPEN workflow shows SILVA and PagerDuty tasks succeeded |

## Splunk vs Dynatrace behaviour

| Behaviour | Splunk | Dynatrace |
|---|---|---|
| Repeat alerts | A new alert every minute while it keeps failing (throttle is off) | One problem stays open; no duplicate pages |
| Recovery | Nothing; the alert just stops firing | Problem closes after 5 clean minutes, CLOSE workflow resolves SILVA and PagerDuty |
| Late logs | Missed if they arrive after the 1-minute search ran | Counted when they arrive in Grail |

## Common mistakes

| Mistake | Fix |
|---|---|
| Copying `*Windows_LDAP as FAILED*` with stars | DQL uses `contains(content, "Windows_LDAP as FAILED")`; no stars needed |
| Using `index` or `sourcetype` fields that don't exist | Use the bucket and fields found in Step 1 |
| Threshold 3 with "Above or equal" | Splunk says greater than 3, so use Above with 3 |
| Forgetting `default: 0` | Quiet minutes become gaps and the alert may not close |
| Going live before fixing routing | Tickets land in the default SILVA team |

## Data flow

```
Cisco ASA firewall
  syslog: %ASA-2-113022 ... group Windows_LDAP as FAILED
    → syslog collector (ActiveGate or forwarder)
    → Grail logs, bucket networksyslog
    → Option A: Anomaly detector runs DQL every minute → count per minute
      Option B: OpenPipeline counts lines → metric log.cisco.vpn.ldap_failed → detector
    → count > 3 in 1 minute
    → Davis event CUSTOM_ALERT "Cisco VPN : LDAP Connections are failing..."
    → Problem P-xxxx
    → OPEN workflow → SILVA incident (network team) + PagerDuty (critical) + email
    → 5 clean minutes → problem closes → CLOSE workflow resolves both
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot of the Splunk alert | Search on `networksyslog`, sourcetype `cisco:asa`, text `Windows_LDAP as FAILED`, every minute, last 1 minute, more than 3 results, Critical, PagerDuty and email |
| Matching ASA message | Usually ASA-2-113022, LDAP server marked FAILED in a AAA server group |
| Dynatrace fit | Static threshold custom alert on a per-minute count matches the Splunk trigger exactly |
| Routing gap | ASA has no OneAgent host entity, so AGO tags are missing and the SILVA group must be set another way |
| Field names | Bucket and ASA identifier fields depend on how networksyslog is ingested; Step 1 confirms them |

## Result

Run Step 1 to confirm the bucket and fields. Create the Option A custom alert with threshold 3, sliding window 1, violating samples 1. Before going live, agree the SILVA team and PagerDuty severity for this alert, because the ASA has no AGO tags. Test with a temporary threshold of 0 or with synthetic syslog lines.

## Related files

| File | Purpose |
|---|---|
| `3-cisco-vpn-ldap-alert-to-dynatrace.dql` | Discovery, alert query and metric version |
| `3-cisco-vpn-ldap-alert-to-dynatrace-anomaly-detector.json` | Example custom alert settings |
| `3.sh` | Synthetic syslog test lines, mirror and git one-liners |
| `2026-10-05/2-splunk-vm-alert-to-dynatrace/` | The Windows VM alert conversion |
| `2026-10-05/1-splunk-spl-to-dynatrace-dql/` | General SPL to DQL mapping |

## Commands

See `3.sh` (not run).
