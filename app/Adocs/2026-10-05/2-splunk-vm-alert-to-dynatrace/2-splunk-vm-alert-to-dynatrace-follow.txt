# Splunk VM Alert To Dynatrace

## Decision tree

```
Move "Windows Application Log eventID 258 on VM" alert from Splunk to Dynatrace
 Step 1: does Dynatrace already get the VM's Windows Application log?
   DQL sample returns rows?               → yes, go to Step 2
   no rows?                               → add a OneAgent log ingest rule for "Windows Application Log"
 Step 2: pick how to alert
   alert on every matching log line?      → Option A: OpenPipeline Davis event (recommended)
   alert only when count passes a limit?  → Option B: Anomaly Detection on a DQL timeseries
   old tenant without OpenPipeline?       → Option C: classic Log events extraction
 Step 3: route it
   host has AGO_* tags?                   → the SILVA and PagerDuty workflow picks it up
   no problem opened?                     → check alerting profile and event.type (must be CUSTOM_ALERT or ERROR)
 Step 4: test
   eventcreate on the VM                  → problem P-xxxx opens → SILVA ticket and PD alert
```

## Short takeaway

| Question | Answer |
|---|---|
| Where the data comes from | OneAgent on the VM reads the Windows Application event log |
| Splunk `EventCode=258` in Dynatrace | `winlog.eventid == "258"` |
| Splunk `sourcetype=WinEventLog:Application` | `log.source == "Windows Application Log"` |
| Splunk scheduled alert | OpenPipeline Davis event (per log line) or Anomaly Detection (threshold) |
| What you get | A Davis problem like the P-261090 one in your screenshot |

## Summary

In Splunk the alert is a scheduled search that runs every few minutes and fires when it finds event 258. In Dynatrace you don't schedule a search. OneAgent already reads the VM's Windows event log, and you tell Dynatrace "when a log line matches this, raise an event". That event becomes a Davis problem, and your existing workflow sends it to SILVA and PagerDuty.

Your screenshot (`event.category: CUSTOM_ALERT`, name "Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa") shows this kind of rule **already exists** in your tenant. Use the steps below to recreate it for other alerts or to check the existing one.

## Typical Splunk alert (assumed)

You didn't paste the SPL, so this is the usual shape. Send me the real one and I'll map it line by line.

```spl
index=wineventlog sourcetype="WinEventLog:Application" EventCode=258 host=TS12* Type=Error
| stats count by host, SourceName, Message
```

Schedule every 5 minutes, trigger when results are more than 0.

## Field mapping

| Splunk | Dynatrace | What it means |
|---|---|---|
| `index=wineventlog` | Not needed (or the bucket the logs go to) | Dynatrace logs from OneAgent land in the default logs bucket unless routed |
| `sourcetype="WinEventLog:Application"` | `log.source == "Windows Application Log"` | Which Windows log |
| `EventCode=258` | `winlog.eventid == "258"` | The event ID |
| `Type=Error` | `loglevel == "ERROR"` | Severity of the log line |
| `SourceName` | `winlog.provider` | The app that wrote the event |
| `host=TS12*` | `startsWith(host.name, "ts12")` or the host entity | Which VM |
| `Message` | `content` | The log text |
| Cron schedule | Not needed | Dynatrace evaluates as logs arrive |
| Trigger "results > 0" | Davis event per match, or threshold > 0 | When to alert |
| Alert action (email, webhook) | Workflow on the problem | Your SILVA and PagerDuty workflow |

Confirm the field names with the Step 1 query; the event id may be stored as text or a number.

## Step 1 — check the logs are already in Dynatrace

```dql
fetch logs, from:-7d
| filter log.source == "Windows Application Log"
| filter winlog.eventid == "258"
| fields timestamp, host.name, loglevel, winlog.provider, winlog.eventid, content
| sort timestamp desc
| limit 20
```

| Result | Next step |
|---|---|
| Rows come back | Logs are ingested, go to Step 2 |
| No rows, but other Windows logs exist | Try `winlog.eventid == 258` without quotes |
| No Windows logs at all | Settings, Log Monitoring, Log ingest rules: add a rule for source "Windows Application Log" on that host or host group |

## Option A — OpenPipeline Davis event (recommended)

This is the Gen3 way and matches your screenshot (`dt.openpipeline.source`).

Where: **OpenPipeline app → Logs → Pipelines** → pick or create the Windows pipeline → **Data extraction → Davis event**.

| Setting | Value |
|---|---|
| Name | Windows App Log eventID 258 |
| Matching condition | `log.source == "Windows Application Log" and winlog.eventid == "258" and loglevel == "ERROR"` |
| event.type | CUSTOM_ALERT |
| event.name | `Error in the Windows Application Log with an eventID 258 on {host.name}` |
| event.description | `{content}` |
| dt.source_entity | `{dt.source_entity}` (keeps the link to the host, so its tags come with it) |

Make sure a **dynamic route** sends Windows Application logs into this pipeline, otherwise the rule never sees them.

| Good | Watch out |
|---|---|
| Fires within seconds of the log line | One event per matching line; many lines in a burst still merge into one problem on the same host |
| No DQL query cost | The problem closes by timeout when lines stop, not by a "recovered" signal |

## Option B — Anomaly Detection on a DQL count

Use this when you want "more than N in 5 minutes" instead of "any single line".

Where: **Anomaly Detection app → Custom alerts → Static threshold**.

```dql
fetch logs
| filter log.source == "Windows Application Log"
| filter winlog.eventid == "258"
| makeTimeseries count = count(), by:{dt.entity.host, host.name}, interval:1m
```

| Setting | Value | What it means |
|---|---|---|
| Threshold | 0 | Alert when the count is above 0 |
| Alert condition | Above | Higher is bad |
| Violating samples | 1 | One bad minute is enough |
| Sliding window | 5 | Look at the last 5 minutes |
| Dealerting samples | 5 | Close after 5 clean minutes |
| event.type | CUSTOM_ALERT | Opens a problem |
| event.name | `Error in the Windows Application Log with an eventID 258 on {dims:host.name}` | Problem title |

A settings JSON example is in `2-splunk-vm-alert-to-dynatrace-anomaly-detector.json`. Check it against your tenant's schema before importing.

## Option C — classic Log events (older tenants)

Settings → Log Monitoring → **Events extraction** → add rule with query `log.source="Windows Application Log" AND winlog.eventid="258"`, event type Custom alert, same title. Use this only if OpenPipeline isn't available to you.

## Step 3 — make sure it reaches SILVA and PagerDuty

| Check | Why |
|---|---|
| The event is tied to the host (`dt.source_entity`) | The host's `AGO_*` tags (support group, environment, domain) are what the OPEN workflow reads |
| The event type opens a problem | CUSTOM_ALERT and ERROR open problems; INFO does not |
| The workflow trigger matches it | Your OPEN workflow fires on problem open, so nothing extra is needed |

## Step 4 — test on the VM

On the Windows VM, in an admin command prompt (this writes a fake event 258):

```
eventcreate /T ERROR /ID 258 /L APPLICATION /SO DTAlertTest /D "Dynatrace alert test eventID 258"
```

| Expected | Where to look |
|---|---|
| Log line appears within about a minute | Run the Step 1 DQL |
| Davis problem opens | Problems app, title starts with "Error in the Windows Application Log" |
| SILVA ticket and PD alert | OPEN workflow execution |

Close it afterwards: with Option B it closes after 5 clean minutes; with Option A it closes when the event times out.

## Common mistakes

| Mistake | Fix |
|---|---|
| Windows Application log not ingested | Add the log ingest rule; OneAgent does not send event logs by default everywhere |
| Event id compared as the wrong type | Try both `"258"` and `258` in Step 1 |
| Davis event not linked to the host | Without `dt.source_entity` the host tags are missing and SILVA routing falls back to the default team |
| Pipeline rule written but no route to it | Add a dynamic route for `log.source == "Windows Application Log"` |
| Copying the Splunk schedule | Not needed; Dynatrace checks logs as they arrive |

## Data flow

```
Windows VM (TS12)
  Application event log: eventID 258, Error
    → OneAgent log module (ingest rule: Windows Application Log)
    → Grail logs (log.source, winlog.eventid, host.name, dt.source_entity)
    → Option A: OpenPipeline Davis event rule
      Option B: Anomaly detector runs DQL every minute
    → Davis event CUSTOM_ALERT on host TS12
    → Problem P-xxxx (host tags AGO_* attached)
    → OPEN workflow → SILVA incident + PagerDuty trigger
    → problem closes → CLOSE workflow → SILVA Resolved + PD resolve
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot | Problem event `CUSTOM_ALERT`, name "Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa", `dt.openpipeline.source: classic_root_cause_analysis` |
| What that tells us | The 258 rule already exists and produces problems that feed the SILVA workflow |
| Splunk SPL | Not provided; used the common WinEventLog Application shape |
| Field names | `winlog.eventid`, `winlog.provider` and `log.source` are the usual OneAgent names; confirm with Step 1 |

## Result

Run Step 1 to confirm the logs and field names. Then create the rule with Option A (any matching line) or Option B (threshold), keep it linked to the host, and test with `eventcreate`. Paste the real Splunk SPL if it has extra filters (message text, specific providers, counts) and I'll convert it exactly.

## Related files

| File | Purpose |
|---|---|
| `2-splunk-vm-alert-to-dynatrace.dql` | Check query and Option B query |
| `2-splunk-vm-alert-to-dynatrace-anomaly-detector.json` | Example anomaly detector settings |
| `2.sh` | Test command for the VM, mirror and git one-liners |
| `2026-10-05/1-splunk-spl-to-dynatrace-dql/` | General SPL to DQL mapping |

## Commands

See `2.sh` (not run).
