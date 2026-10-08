# Application Incident Analysis Summary

## Decision tree

```
Splunk: Application Incident Analysis (Edit Search, not Edit Alert)
 Does it notify anyone? → no email, no PagerDuty → NOT an alert → no detector
 What does it do?
  reads lookup monitor_logs (OK or NG results written by other monitoring searches)
  keeps yesterday's rows → counts OK, NG, Maintenance per application
  collect → writes 1 row per application into monitoring_summary_idx (46 rows on 10/8)
 Who uses monitoring_summary_idx?
  a dashboard or monthly report → Dynatrace dashboard that queries live (this tf)
  nobody → do not migrate
 Where does monitor_logs come from?
  other Splunk searches with outputlookup monitor_logs → find them (.spl query 1)
  → in Dynatrace, query those sources directly, or upload the CSV as a Grail lookup
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this an alert? | No. It is a scheduled report that writes a daily summary. Nobody gets notified. |
| What does it calculate? | For yesterday, per application: how many checks were OK, NG, and in maintenance |
| Where does the result go? | Splunk summary index `monitoring_summary_idx`, sourcetype `application_summary` |
| When does it run? | About 01:00 JST daily (events at 01:00:18) |
| Dynatrace equivalent | A dashboard. Grail can query the data directly, so no summary index is needed. |
| Terraform | `dynatrace_document` of type dashboard with 2 table tiles |
| Biggest unknown | What fills `monitor_logs`. It must be found before this can work in Dynatrace. |

## Summary

This search is a nightly roll-up. It reads the `monitor_logs` lookup, which other monitoring searches fill with OK or NG results, and stores yesterday's totals per application in a summary index for reports. Dynatrace does not need a summary index because dashboards query Grail directly, so the replacement is a dashboard. It only works once the data behind `monitor_logs` is available in Dynatrace.

## Splunk query line by line

| Splunk part | What it means | DQL |
|---|---|---|
| `\| inputlookup monitor_logs` | Read the monitor_logs lookup table (a CSV in Splunk) | `load "/lookups/monitor_logs"` |
| `eval ctime=strftime(time,"%Y-%m-%d")` | Turn each row's epoch time into a date | `formatTimestamp(timestampFromUnixSeconds(toLong(time)), format:"yyyy-MM-dd", timezone:"Asia/Tokyo")` |
| `eval yesterday=strftime(relative_time(now(),"-1d@d"),"%Y-%m-%d")` | Yesterday's date | `formatTimestamp(now() - 1d, format:"yyyy-MM-dd", timezone:"Asia/Tokyo")` |
| `where ctime = yesterday` | Keep only yesterday's rows | `filter ctime == ...` |
| `count(eval(status="OK")) as OK` | Count OK checks | `OK = countIf(status == "OK")` |
| `count(eval(status="NG")) as NG` | Count failed checks | `NG = countIf(status == "NG")` |
| `count(eval(isMaintenance="true")) as Maintenance` | Count checks during maintenance | `Maintenance = countIf(isMaintenance == "true")` |
| `by ctime application` | One row per date and application | `by:{ ctime, application }` |
| `collect index=monitoring_summary_idx` | Save the result as events in a summary index | Not needed; the dashboard runs the query live |

## Terraform

File: `9-application-incident-analysis-summary.tf`

```hcl
resource "dynatrace_document" "application_incident_analysis" {
  type = "dashboard"
  name = "Application Incident Analysis"
  content = jsonencode({
    version   = 15
    variables = []
    tiles = {
      "0" = {
        type          = "data"
        title         = "Yesterday: OK, NG and Maintenance per application"
        query         = local.app_incident_daily_query
        visualization = "table"
      }
      "1" = {
        type          = "data"
        title         = "Last 30 days: applications with NG"
        query         = local.app_incident_30d_query
        visualization = "table"
      }
    }
    layouts = {
      "0" = { x = 0, y = 0, w = 24, h = 10 }
      "1" = { x = 0, y = 10, w = 24, h = 10 }
    }
  })
}
```

Yesterday tile query:

```
load "/lookups/monitor_logs"
| fieldsAdd ctime = formatTimestamp(timestampFromUnixSeconds(toLong(time)), format:"yyyy-MM-dd", timezone:"Asia/Tokyo")
| filter ctime == formatTimestamp(now() - 1d, format:"yyyy-MM-dd", timezone:"Asia/Tokyo")
| summarize OK = countIf(status == "OK"),
            NG = countIf(status == "NG"),
            Maintenance = countIf(isMaintenance == "true"),
            by:{ ctime, application }
| sort NG desc, application asc
```

## The monitor_logs problem

| Fact | Consequence |
|---|---|
| In Splunk, other searches keep appending to `monitor_logs` | It is a living table |
| In Dynatrace, a Grail lookup is a file you upload | It does not grow by itself |
| So uploading the CSV once gives a frozen snapshot | The dashboard would stop changing |
| Real fix | Find the searches that write `monitor_logs`, then query their log sources directly in Dynatrace |

Run `.spl` query 1 in Splunk to list every saved search that mentions `monitor_logs`.

## Data flow

```
Splunk today:
 monitoring searches → outputlookup monitor_logs (OK or NG per check)
   → 01:00 Application Incident Analysis → collect → monitoring_summary_idx → report or dashboard

Dynatrace:
 source logs of those checks → Grail
   → dashboard tile queries live (no summary index, no nightly job)
```

## Investigation

| Screenshot | Finding |
|---|---|
| 1 (Edit Search) | Title Application Incident Analysis; search shown above; no earliest or latest time; no trigger or action (it is a report) |
| 2 (summary index search) | `index=monitoring_summary_idx sourcetype=application_summary`: 46 events, all at 10/8 01:00:18, host CEAA2101, fields application, OK, NG, Maintenance |

## Result

| Step | What to do |
|---|---|
| 1 | Run `.spl` query 1 to find what writes `monitor_logs` |
| 2 | Ask who reads `monitoring_summary_idx` (dashboard or monthly report). If nobody, do not migrate. |
| 3 | If needed: upload a `monitor_logs` CSV as a Grail lookup for a first test, then replace with the real sources |
| 4 | Export any Dynatrace dashboard JSON and compare the `version` field before apply |
| 5 | `terraform plan` should show 1 document to add |

## Related files

| File | Purpose |
|---|---|
| `9-application-incident-analysis-summary.tf` | Dashboard as Terraform |
| `9-application-incident-analysis-summary-check.dql` | Check queries |
| `9-application-incident-analysis-summary.spl` | Splunk queries to trace monitor_logs |
| `9.sh` | Commands |

## Commands

See `9.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/9-application-incident-analysis-summary"
terraform init
terraform validate
terraform plan
```
