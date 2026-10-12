# InnoRules BRE Alert Detector

## Decision tree

```
innorules.tf ("dynatrace_log_alert")
 resource type not in provider → dynatrace_davis_anomaly_detectors
 cron */5 1-5 * * * → runs only 01:00-05:59
   detector has no schedule → filter on log hour inside the query
   which timezone? → UTC cron: keep getHour(); JST cron: use Asia/Tokyo filter
 two log group checks → one is enough
 only action PagerDuty → pagerduty.enabled "1", severity high
 integration key in old file → removed; rotate if committed
 "ERROR" case-insensitive → may match normal text → check query 2
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | The `dynatrace_log_alert` resource became a Records detector. |
| Query | Same filters, 5-minute window, plus an hour filter for 01:00 to 05:59. |
| Severity and paging | High, PagerDuty on (it was the only action). |
| Email | None in the old file. |
| Open question | Was the old cron in UTC or JST? It changes which hours are watched. |

## Summary

BRE (business rules engine) InnoRules errors page PagerDuty, but only during hours 1 to 5. A detector runs all day, so the hour limit moves into the query as a filter on the log timestamp. The filter is written for UTC; if the old schedule was in Japan time, swap in the Asia/Tokyo version.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| BRE | Business rules engine. InnoRules is the product. | The system being watched. |
| Cron `*/5 1-5 * * *` | Every 5 minutes, only when the hour is 1, 2, 3, 4 or 5. | The alert only watched a night or daytime window. |
| `getHour(timestamp)` | DQL function that returns the hour of a timestamp, in UTC. | Rebuilds the hour window. |
| `formatTimestamp(..., timezone:"Asia/Tokyo")` | Formats a time in Japan time. | Used if the old cron was JST. |
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces the scheduled alert. |

### Old field to new place

| Old field | Old value | New place |
|---|---|---|
| `alert_name` | `BRE alert` | `title` |
| `description` | alert when logs from innorules-* contains loglevel error | `description`, with the hour window noted |
| Log group filter | `/aws/lambda/innorules` or `innorules` | `contains(aws.log_group, "innorules")` |
| Content filter | "ERROR", case-insensitive | Unchanged |
| `cron_expression` | `*/5 1-5 * * *` | `getHour(timestamp)` between 1 and 5 |
| `time_range` | `LAST_5_MINUTES` | `from:now()-5m` |
| `expires` | 24 | Not needed |
| `trigger_conditions` | Results > 0, once | Detector default |
| `PAGERDUTY` | Integration key, "BRE alert: InnoRules ERROR detected" | `pagerduty.enabled = "1"`; text in `event.name` |

### Which hours?

| If the old cron ran in | Hours watched | What to use |
|---|---|---|
| UTC | 01:00 to 05:59 UTC, which is 10:00 to 14:59 in Japan | The query as written |
| JST | 01:00 to 05:59 in Japan | The Asia/Tokyo filter below |

Query 3 in the check file shows errors per hour in both timezones, which helps decide.

### Things to know

| Point | What it means |
|---|---|
| Errors outside the window are ignored | Same as before: the old alert never ran outside hours 1 to 5. |
| PagerDuty key | It looks the same as the key in the CCI timeout alert (answer 1), so both page the same service. It was in plain text; rotate it if the file was committed. |
| "ERROR" ignores case | It also matches "error" in ordinary text. A noisy match here wakes someone up, so run query 2. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "bre_alert_innorules" {
  title       = "BRE alert"
  description = "Alert when logs from innorules-* contain log level error (01:00-05:59 only)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "innorules")
          | filter contains(content, "ERROR", caseSensitive:false)
          | filter getHour(timestamp) >= 1 and getHour(timestamp) <= 5
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "BRE alert: InnoRules ERROR detected"
      }
      property {
        key   = "event.description"
        value = "InnoRules (BRE) logged an ERROR. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "InnoRules"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
```

Asia/Tokyo version of the hour filter (replace the `getHour` line if the old cron was JST):

```
| fieldsAdd hour_jst = toLong(formatTimestamp(timestamp, format:"H", timezone:"Asia/Tokyo"))
| filter hour_jst >= 1 and hour_jst <= 5
```

### Before you apply

| Step | Why |
|---|---|
| Confirm the old cron timezone | Decides which hour filter to use. |
| Run query 1 | Confirms the log group names. |
| Run query 2 | Shows how much of the "ERROR" match is noise. |
| Run query 3 | Shows errors per hour in UTC and JST. |
| Rotate the PagerDuty key if the old file was committed | It was in plain text. |
| Run `terraform validate` and `terraform plan` from `12.sh` | Checks the file before apply. |

## Data flow map

```
InnoRules (BRE) logs a line containing "ERROR"
  → CloudWatch Logs
  → Dynatrace Grail logs
  → Records detector, every minute, last 5 minutes
      log hour 1 to 5 → problem (high)
      other hours     → ignored
  → workflow: pagerduty.enabled = "1" → PagerDuty incident
```

## Related files

| File | What it is |
|---|---|
| `12-innorules-bre-alert-tf.tf` | Converted Terraform (with the JST filter in a comment) |
| `12-innorules-bre-alert-tf-check.dql` | Log group, noise and per-hour checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Field mapping |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `12.sh` | Commands |

## Commands

All commands are in [`12.sh`](12.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/12-innorules-bre-alert-tf"
terraform init
terraform validate
terraform plan
```
