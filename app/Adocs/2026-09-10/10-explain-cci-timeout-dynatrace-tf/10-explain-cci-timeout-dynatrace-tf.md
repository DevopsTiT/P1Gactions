# Explain CCI Timeout Dynatrace TF

```
What does this .tf do?
  → Turn Splunk log alert into Dynatrace log-metric + metric events
Why 3 resources?
  → 1 metric from logs + Critical alert + Warning alert
What is NOT here?
  → PagerDuty key (use Problem notification instead)
```

| Key point | Detail |
| --- | --- |
| File | `alerting_cci_aws_batch_timeout_dynatrace.tf` |
| Goal | Migrate Splunk `CCI_AWS_Batch Time Out` to Dynatrace |
| Style | Same idea as ContactManager `dynatrace_metric_events` |

## Summary

Splunk searched logs every 5 minutes and paged if any “Task timed out” lines appeared. Dynatrace cannot use that Splunk search as-is. This file **counts matching Grail logs into a metric**, then **alerts when that count goes above 0** — Critical fast (~5 min), Warning if it stays up ~10 min.

---

## Big picture flow

```
Lambda /aws/lambda/cci-fa-comm-calc writes logs
        │
        ▼
Grail logs (content has "Task timed out", not DEBUG)
        │
        ▼
dynatrace_log_metrics
  key = log.cci.aws.batch.task_timed_out
  (counts matching lines, split by host.name)
        │
        ▼
dynatrace_metric_events (Critical / Warning)
  ABOVE threshold 0 → Davis/Problem event
        │
        ▼
Problem notification → PagerDuty / ServiceNow (configured outside this file)
```

---

## Block 1 — `terraform` / `provider` (lines 7–17)

| Line / field | What it means | Why you care |
| --- | --- | --- |
| `required_providers` | Declares the Dynatrace Terraform plugin | Same family as your CM MQ repo (`~> 1.30.0`) |
| `source = "dynatrace-oss/dynatrace"` | Official OSS provider | Talks to Dynatrace Settings APIs |
| `provider "dynatrace" {}` | Empty block | Auth usually from env: `DYNATRACE_ENV_URL`, `DYNATRACE_API_TOKEN` |

No variables: everything is hardcoded in this one file.

---

## Block 2 — `dynatrace_log_metrics` (lines 22–35)

**What this is:** A rule that turns **log lines** into a **number (metric)** Dynatrace can chart and alert on.

| Field | Value in file | Plain English |
| --- | --- | --- |
| `enabled` | `true` | Metric is active |
| `key` | `log.cci.aws.batch.task_timed_out` | Metric name (must start with `log.`) |
| `measure` | `OCCURRENCE` | Count how many log records match (like Splunk result count) |
| `query` | matcher string | Which logs count |
| `dimensions` | `["host.name"]` | Split counts per host (like Splunk by host) |

### The `query` matcher (most important)

```
matchesPhrase(content, "Task timed out")
and not matchesPhrase(content, "DEBUG")
and matchesPhrase(aws.log_group, "/aws/lambda/cci-fa-comm-calc")
```

| Part | Splunk equivalent | Meaning |
| --- | --- | --- |
| `matchesPhrase(content, "Task timed out")` | `"Task timed out"` | Line must contain that phrase |
| `not matchesPhrase(..., "DEBUG")` | `message!=*DEBUG*` | Ignore debug noise |
| `matchesPhrase(aws.log_group, "/aws/lambda/cci-fa-comm-calc")` | `index=cci-fa-comm-calc` (approx) | Only that Lambda log group |

**If `aws.log_group` is missing** on your ingested logs, the scoped query matches nothing. Use the commented broader query (Task timed out + not DEBUG only), then tighten later with another field you do have.

### Why a log metric first?

ContactManager MQ alerts already had **metrics** (`guidewire.messaging.failed`). Splunk CCI alert only had **logs**. Dynatrace metric events need a metric — so this resource creates one from logs.

---

## Block 3 — Critical `dynatrace_metric_events` (lines 40–68)

**What this is:** Same resource type as ContactManager MQ Critical alerts. It watches the metric and opens an **ERROR** event when the condition is true.

### Top-level fields

| Field | Value | Meaning |
| --- | --- | --- |
| `enabled` | `true` | Alert is on |
| `event_entity_dimension_key` | `host.name` | Attach event to that dimension (CM used `queue.name`) |
| `summary` | `CCI_AWS_Batch Time Out Critical` | Name in Dynatrace UI list |

### `event_template` — what humans see

| Field | Meaning |
| --- | --- |
| `title` | Problem/event title; `{dims:host.name}` fills the host |
| `description` | Longer text; `{alert_condition:value}` is current metric value |
| `event_type` | `ERROR` = severity like CM Critical |
| `davis_merge` | `false` = do not merge into other Davis problems aggressively |

### `model_properties` — when it fires (maps Splunk schedule)

| Field | Value | Meaning |
| --- | --- | --- |
| `type` | `STATIC_THRESHOLD` | Fixed number threshold (not anomaly baseline) |
| `alert_condition` | `ABOVE` | Fire when metric **>** threshold |
| `threshold` | `0` | Same as Splunk **results > 0** |
| `samples` | `5` | Look at last 5 one-minute samples ≈ **5 minutes** (Splunk cron `*/5`) |
| `violating_samples` | `1` | Need **1** sample above 0 → fire fast on first timeout spike |
| `dealerting_samples` | `5` | Need 5 good samples to clear |
| `alert_on_no_data` | `false` | Silence is OK (no log ≠ alert); CM MQ often used `true` for queues |

### `query_definition` — which metric

```
log.cci.aws.batch.task_timed_out:splitBy("host.name"):sum
```

| Piece | Meaning |
| --- | --- |
| metric key | From the log metric resource |
| `splitBy("host.name")` | Per-host series (matches dimension) |
| `sum` | Sum occurrences in the interval |

### `depends_on`

Terraform creates the **log metric before** the alert so the metric key exists.

---

## Block 4 — Warning `dynatrace_metric_events` (lines 73–101)

Same shape as ContactManager **Warning** (`event_type = "RESOURCE"`).

| Difference vs Critical | Warning value | Why |
| --- | --- | --- |
| `event_type` | `RESOURCE` | Lower severity (like CM warning) |
| `samples` | `10` | ~10 minute window |
| `violating_samples` | `10` | Must stay above 0 for **all** 10 samples (sustained) |
| `threshold` | `0` | Still “any timeout”, but must persist |

Critical = “saw a timeout recently.”  
Warning = “timeouts keep showing for ~10 minutes.”

---

## What this file does **not** do

| Missing | Where to handle it |
| --- | --- |
| PagerDuty integration key | Dynatrace **Problem notifications** (or ServiceNow), not inside `metric_events` |
| Splunk index name | Replaced by log group / content matcher on Grail logs |
| Log ingest itself | OneAgent / Firehose / OpenPipeline must already bring Lambda logs into Grail |

---

## Side-by-side with Splunk

| Splunk setting | This Terraform |
| --- | --- |
| Alert name `CCI_AWS_Batch Time Out` | `summary` / `title` on metric events |
| Search | `dynatrace_log_metrics.query` |
| Cron every 5 min | Critical `samples = 5` |
| Results > 0 | `threshold = 0` + `ABOVE` |
| Trigger once | One event evaluation (not per-log storm) |
| Expires 24h | Dynatrace problem lifecycle (not this field) |
| PagerDuty | Separate notification config |

---

## How to verify after apply

1. Confirm logs exist (DQL):

```dql
fetch logs
| filter contains(content, "Task timed out")
| filter not contains(content, "DEBUG")
| fields timestamp, host.name, content
| limit 20
```

2. Metrics browser / Data Explorer: metric `log.cci.aws.batch.task_timed_out`  
3. Settings → Anomaly detection → Metric events: see Critical + Warning  
4. Fake or wait for a real timeout → Problem appears → check notification

---

## Common failures

| Symptom | Likely cause |
| --- | --- |
| Metric always 0 | Matcher too strict (`aws.log_group` missing) |
| No alert | Metric not created / wrong key / timeframe |
| Alert too noisy | Lower violating_samples or add throttle via notification profile |
| No page to phone | Problem notification / PD not wired |

---

## Result

This `.tf` is a **three-step migration**: count matching CCI timeout logs → alert if count > 0 (~5 min) → optional sustained warning (~10 min). PagerDuty stays outside, like other Dynatrace Problems.
