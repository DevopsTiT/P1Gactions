# Claim Job Over Run Alert

## Decision tree

```
Splunk: claims jobs with start_time, no end_time, elapsed >= 15 min, last 24 h
 index="controlm*" → Control-M agent daily log (daily_ctmag_*.log)
 [| inputlookup claims_jobs] → claims_jobs array (fill job names from the lookup)
 start_time / end_time fields → STARTED line and ENDED line per run
 stats latest(...) by job_name → summarize min(start), max(end) by job_name, order_id, run_no
 where isnull(endtime) → filter isNull(ended)
 where elapsed >= 15 → elapsed_min >= 15
 every 5 min → detector every minute (fine)
 email → medium, PagerDuty 0
 15 minutes too short for some jobs? → check query 4 → per job limits
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it catch? | A claims Control-M job that started 15 or more minutes ago and has not ended. |
| Log used | Control-M agent daily log `daily_ctmag_YYYYMMDD.log`. |
| Start | Line with `) STARTED (`. |
| End | Line with `EXECUTION ENDED`, `ENDED OK` or `ENDED NOTOK`. |
| Job list | `claims_jobs` array. You must fill it from the Splunk lookup. |
| Identity | `job_name`, one problem per job. |
| Severity | medium, PagerDuty off. |

## Summary

Splunk takes the claims job list from a lookup, finds each job's latest start time, and alerts when there is no end time after 15 minutes. Dynatrace has no Splunk lookup, so the job names go into an array in the query. The start and end come from the agent log lines shown in the second screenshot, matched per run by ORDERID and RUNNO.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Over run | A job running longer than expected. | The thing this alert catches. |
| `inputlookup` | Splunk reads a CSV table, here the list of claims jobs. | Dynatrace needs that list typed into the query. |
| ORDERID | Control-M's id for one ordered run of a job. | Ties a STARTED line to its ENDED line. |
| RUNNO | Run number. Goes up when a job is rerun. | A rerun is a separate run. |
| `summarize ... by` | Group rows and compute values per group. | Gives one row per run with start and end. |
| `min(if(...))` | Smallest value only among rows that match. | Picks the STARTED time out of mixed lines. |

### What the screenshots show

| Item | Value |
|---|---|
| Alert | Claim Job Over Run Alert |
| Time range | Last 24 hours |
| Cron | Every 5 minutes |
| Trigger | More than 0 results, once, no throttle |
| Action | Send email to the claims incident group. Recipients not copied. |
| Hosts in controlm index | CEAA2090, CEAA204F, CEAA20CB, CEAA204E and others (8 in total) |
| Source | /opt/ctmhlx/ctm/dailylog/daily_ctmag_20261012.log |
| Sourcetype | controlm_agent_log |
| Start line | `JOB DYDB033A (ORDERID 31777, RUNNO 00001) STARTED (3867048), OWNER ftpdy, APPL TYPE OS` |
| End lines | `... EXECUTION ENDED` and `... ENDED OK elapsed - 0.67 Sec` |

### Splunk to Dynatrace

| Splunk piece | Dynatrace form |
|---|---|
| `index="controlm*"` | `contains(log.source, "daily_ctmag_")` |
| `[\| inputlookup claims_jobs \| table job_name]` | `claims_jobs = array(...)` then `filter in(job_name, claims_jobs)` |
| `start_time` | Time of the `) STARTED (` line. |
| `end_time` | Time of the `ENDED` line. |
| `Time=strptime(start_time, ...)` | Not needed. Log timestamps are already times. |
| `elapsed=round((now()-Time)/60)` | `toLong((now() - started) / 1m)` |
| `starttime = substr(...)` formatting | `formatTimestamp(started, format:"yyyy/MM/dd HH:mm:ss", timezone:"Asia/Tokyo")` |
| `stats latest(...) by job_name` | `summarize min(...), max(...) by job_name, order_id, run_no` |
| `where isnull(endtime)` | `filter isNull(ended)` |
| `where elapsed>="15"` | `filter elapsed_min >= 15` |
| Last 24 hours | `from:now()-24h` |
| Cron every 5 minutes | Dropped. Detector runs every minute. |
| More than 0 results, once | Rows after the last filter fire. |
| Throttle off | Identity `job_name`. |
| Send email | `medium`, PagerDuty `0`. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "claim_job_over_run" {
  title       = "Claim Job Over Run Alert"
  description = "A claims Control-M job started 15 or more minutes ago and has not ended. One problem per job_name."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(log.source, "daily_ctmag_", caseSensitive:false)
          | filter contains(content, ") STARTED (") or contains(content, ") EXECUTION ENDED")
              or contains(content, ") ENDED OK") or contains(content, ") ENDED NOTOK")
          | parse content, "LD 'JOB ' NSPACE:job_name SPACE '(ORDERID ' INT:order_id ', RUNNO ' INT:run_no ')'"
          | fieldsAdd claims_jobs = array("CLAIMJOB01", "CLAIMJOB02")
          | filter in(job_name, claims_jobs)
          | fieldsAdd is_start = contains(content, ") STARTED ("),
                      is_end = contains(content, " ENDED")
          | summarize started = min(if(is_start, timestamp)),
                      ended = max(if(is_end, timestamp)),
                      host = takeFirst(host.name),
                      by:{ job_name, order_id, run_no }
          | filter isNotNull(started) and isNull(ended)
          | fieldsAdd elapsed_min = toLong((now() - started) / 1m),
                      starttime = formatTimestamp(started, format:"yyyy/MM/dd HH:mm:ss", timezone:"Asia/Tokyo")
          | filter elapsed_min >= 15
          | fields job_name, order_id, run_no, starttime, elapsed_min, host
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "job_name"
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
        value = "Claim job over run"
      }
      property {
        key   = "event.description"
        value = "A claims Control-M job has been running 15 minutes or more without an ENDED line. See job_name, starttime and elapsed_min on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "claims"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
```

### Things to check

| Check | Why |
|---|---|
| Fill `claims_jobs` | Run `\| inputlookup claims_jobs \| table job_name` in Splunk and paste the names into the array. Without this the alert never fires. |
| Check query 1 | Confirms the agent daily logs reach Dynatrace. |
| Check query 2 | Every STARTED and ENDED row should have job_name, order_id and run_no filled. |
| Check query 3 | Shows every run open right now. Useful for a dry run before the claims filter. |
| Check query 4 | Normal run time per job. If a claims job normally runs 30 minutes, 15 minutes will alert every day. |
| Splunk `elapsed>="15"` | In Splunk `where`, quoted "15" is text, so the comparison may be text-based. The Dynatrace version compares numbers, which is what was meant. |
| Long list of jobs | If the claims list is long, upload it as a Dynatrace lookup table and use `lookup` instead of the array. |

## Data flow map

```
Control-M agent runs a claims job
  → daily_ctmag log: "JOB X (ORDERID n, RUNNO r) STARTED"
  → (later) "... EXECUTION ENDED" / "ENDED OK"
  → Dynatrace Grail logs
  → detector every minute, last 24 h
       keep claims jobs only
       group by job, ORDERID, RUNNO → start time, end time
       no end and 15+ min since start → row
  → problem per job_name (medium)
  → workflow: pagerduty.enabled = "0" → email
  → ENDED line arrives → row disappears → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `40-claim-job-over-run-tf.tf` | Full Terraform. |
| `40-claim-job-over-run-tf-check.dql` | Four check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `40.sh` | Commands, one per line. |

## Commands

All commands are in [`40.sh`](./40.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/40-claim-job-over-run-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/40-claim-job-over-run-tf
git commit -m "Claim job over run detector"
git push
```
