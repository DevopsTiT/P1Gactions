# Datalake Detector Terraform Explained

## Decision Tree

```
Reading 43-datalake-batch-result-detector.tf
 terraform { } + provider { }  → "which plugin, how to log in"
 resource dynatrace_davis_anomaly_detectors → "the alert itself"
   analyzer → "what to measure and when it is bad"
     query          → count batch_monitoring lines per minute
     threshold 0 + ABOVE → any line is "bad"
     violating 1 / window 5 → 1 bad minute in the last 5 opens a problem
     dealerting 60  → 60 good minutes close it
   event_template → "what the problem says and how it is routed"
   execution_settings {} → defaults
```

## Short Takeaway

| Question | Answer |
|---|---|
| What does the file create? | One Dynatrace alert (a Davis anomaly detector) |
| What does it watch? | Log lines from the Datalake batch monitoring log |
| When does it fire? | As soon as any such line appears in a minute |
| When does it close? | After 60 minutes in a row with no new lines |
| Who gets told? | The standard notification flow (email or SILVA), no paging |

## Summary

The file has two parts. The top tells Terraform to use the Dynatrace plugin. The bottom defines one alert: every minute Dynatrace counts the batch monitoring lines, and if the count is above zero it opens a problem. The problem stays open while the batch keeps writing and closes an hour after the last line.

## Part 1: Setup Blocks

```hcl
terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}
```

| Block | What it means | Why you care |
|---|---|---|
| `terraform { required_providers }` | Tells Terraform to download the Dynatrace plugin (provider) | Without it, Terraform does not know what a Dynatrace resource is |
| `provider "dynatrace" {}` | Connects the plugin to your tenant | Login comes from environment variables `DT_ENV_URL` and `DT_PLATFORM_TOKEN`, so no secret is in the file |

## Part 2: The Alert Resource

```hcl
resource "dynatrace_davis_anomaly_detectors" "datalake_batch_result" {
  title       = "Prod_Datalake_BatchResult_Normal"
  description = "Datalake batch monitoring wrote lines to batch_monitoring_logs. Check the batch result."
  enabled     = true
  source      = "Davis Anomaly Detection"
```

| Line | What it means |
|---|---|
| `resource "dynatrace_davis_anomaly_detectors"` | The type: a Davis anomaly detector, Dynatrace's custom alert |
| `"datalake_batch_result"` | Terraform's own name for it; used in state and plan output |
| `title` | Name shown in Dynatrace. `Prod` = production, `_Normal` = not urgent |
| `description` | Text shown on the detector |
| `enabled = true` | The alert is switched on |
| `source` | Label for where the detector comes from |

## Part 3: The Analyzer (What to Measure)

```hcl
name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
```

A **static threshold** analyzer compares a number against a fixed limit you choose. (The other kind, auto-adaptive, learns a normal range by itself; seq 35 used that.)

### The query

```
fetch logs
| filter matchesValue(log.source, "*batch_monitoring*")
| makeTimeseries count = count(default: 0), interval:1m
```

| Step | What it does |
|---|---|
| `fetch logs` | Read log lines stored in Dynatrace Grail |
| `filter matchesValue(log.source, "*batch_monitoring*")` | Keep only lines whose source name contains `batch_monitoring` (the Splunk index). This is a guess to confirm |
| `makeTimeseries count = count(default: 0), interval:1m` | Turn lines into a number per minute. Minutes with no lines become 0 instead of empty |

Example: if the batch writes 3 lines at 07:02 and 1 at 07:03, the series is `07:01 = 0`, `07:02 = 3`, `07:03 = 1`, `07:04 = 0`.

### The rule settings

| Setting | Value | What it means | In the example |
|---|---|---|---|
| `threshold` | 0 | The limit | |
| `alertCondition` | ABOVE | A minute is bad when count is above the limit | 07:02 and 07:03 are bad |
| `alertOnMissingData` | false | No data is not treated as a problem | Quiet days stay quiet |
| `slidingWindow` | 5 | Look at the last 5 minutes | |
| `violatingSamples` | 1 | 1 bad minute in that window opens the problem | Opens at 07:02 |
| `dealertingSamples` | 60 | 60 good minutes in a row close it | Closes about 08:03 |

Why 60: a batch may write lines spread over many minutes. A short close time would open and close several problems for one run. 60 keeps one run as one problem.

## Part 4: Event Template (What the Problem Says)

| Property | Value | What it means |
|---|---|---|
| `event.type` | CUSTOM_ALERT | Creates a problem that can trigger notifications |
| `event.name` | Prod_Datalake_BatchResult_Normal | Problem title |
| `event.description` | Datalake batch monitoring wrote lines... | Problem text |
| `alert.severity` | low | Informational, like Splunk priority Normal |
| `app.name` | Datalake | Log problems have no host, so this tells the standard flow who owns it |
| `pagerduty.enabled` | 0 | The standard flow should not page anyone for this |

`execution_settings {}` keeps the default settings (for example, which identity runs the query).

## Splunk vs This Detector

| Topic | Splunk | Dynatrace detector |
|---|---|---|
| When it checks | Once a day at 08:00 | Every minute |
| What triggers | Any line "today" | Any line in a minute |
| What you receive | One email with all lines | One problem per batch run, without the lines |
| How to see the lines | In the email | check.dql query 2 or the Logs app |

## Common Mistakes

| Mistake | Result | Fix |
|---|---|---|
| `log.source` filter does not match the real logs | Detector never fires | Run check.dql query 1 and correct the filter |
| batch_monitoring_logs holds normal success lines | A problem every run | Add a failure filter (check.dql query 4) |
| Applying this and the seq 29 or 42 workflow | Two notifications for the same thing | Keep only one |
| Setting `dealertingSamples` to 1 | Many open-close problems per run | Keep a long close time |

## Data Flow

```
batch job writes lines → Grail logs
  → every minute: count lines with log.source ~ batch_monitoring
  → count > 0 ? → yes → problem opens (low, Datalake, no page)
                         → standard flow → email / SILVA
  → 60 minutes with count 0 → problem closes
```

## Investigation

| Checked | Evidence |
|---|---|
| File | `43-datalake-batch-result-detector.tf`, 2 setup blocks and 1 resource |
| Analyzer | Static threshold, 7 inputs |
| Event template | 6 properties |
| Secrets | None; auth from environment variables |

## Result

| Step | What to do |
|---|---|
| 1 | Confirm the `log.source` filter with seq 43 check.dql query 1 |
| 2 | Decide on a failure filter with query 4 |
| 3 | `terraform plan` shows 1 to add |

## Related Files

| File | Purpose |
|---|---|
| `43-datalake-batch-result-detector/43-datalake-batch-result-detector.tf` | The file explained here |
| `43-datalake-batch-result-detector/43-datalake-batch-result-detector-check.dql` | Check queries |
| `44.sh` | Commands |

## Commands

See `44.sh`.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/43-datalake-batch-result-detector"
terraform init
terraform validate
terraform plan
```
