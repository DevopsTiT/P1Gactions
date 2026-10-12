# Claim Job Over Run TF Explained

## Decision tree

```
Reading the tf top to bottom
 terraform + provider blocks → "use the Dynatrace plugin" (boilerplate)
 resource block → one Dynatrace detector named claim_job_over_run
   title, description, enabled → what people see
   analyzer → the brain: runs the DQL every minute
     query.expression → which rows mean "problem"
     alertIdentityFields → how rows group into problems (job_name)
   event_template → what the problem looks like (name, severity, PagerDuty flag)
   execution_settings → defaults (empty)
 query returns rows? → yes → problem open → workflow → email
                     → no → problem closes
```

## Short takeaway

| Question | Answer |
|---|---|
| What is the tf? | A recipe that creates one Dynatrace alert (a Davis anomaly detector). |
| What does the alert do? | Every minute it looks for claims jobs that started 15+ minutes ago and have not ended. |
| How does it know start and end? | From Control-M agent log lines: `STARTED` and `ENDED`. |
| One problem per? | Job name. |
| What do I still need to do? | Put the real claims job names into `claims_jobs`. |

## Summary

The Terraform file has three parts: setup, the detector, and the problem template. The detector's heart is the DQL query. It reads 24 hours of Control-M logs, pairs each job's start line with its end line, and keeps only runs that are still open after 15 minutes. Any row left at the end becomes a problem.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Terraform | A tool that creates cloud settings from text files. | You review the file, then `terraform apply` creates the alert. |
| Provider | The plugin Terraform uses to talk to a product, here Dynatrace. | Without it Terraform cannot create Dynatrace things. |
| Resource | One thing Terraform creates. | Here it is one alert. |
| Davis anomaly detector | A Dynatrace alert that runs a query on a schedule. | It replaces the Splunk saved search. |
| DQL | Dynatrace Query Language, used to search logs. | The alert logic lives in DQL. |
| Problem | Dynatrace's word for an open alert. | Opens when the query returns rows, closes when it returns none. |
| Identity field | The field that decides which rows belong to the same problem. | Stops one stuck job from making a new problem every minute. |

### Part 1: Setup blocks

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

| Line | What it means |
|---|---|
| `required_providers` | Tells Terraform to download the Dynatrace plugin. |
| `source = "dynatrace-oss/dynatrace"` | Where the plugin comes from (the public Terraform registry). |
| `provider "dynatrace" {}` | Use the plugin. The URL and token come from environment variables, so no secrets are in the file. |

### Part 2: The detector header

```hcl
resource "dynatrace_davis_anomaly_detectors" "claim_job_over_run" {
  title       = "Claim Job Over Run Alert"
  description = "A claims Control-M job started 15 or more minutes ago and has not ended. One problem per job_name."
  enabled     = true
  source      = "Davis Anomaly Detection"
```

| Line | What it means |
|---|---|
| `dynatrace_davis_anomaly_detectors` | The kind of thing to create: a detector. |
| `claim_job_over_run` | Terraform's own nickname for it. Not shown in Dynatrace. |
| `title` | The name you see in Dynatrace. Same as the Splunk alert name. |
| `description` | Plain-English purpose. |
| `enabled = true` | The alert is on. |
| `source` | Fixed value for this kind of detector. |

### Part 3: The analyzer (the brain)

```hcl
  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
```

`RecordAnomalyDetectionAnalyzer` means: run the query, and if it returns any rows, that is an anomaly. It runs every minute.

### Part 4: The query, line by line

Example job used below: `CLMB001`, ORDERID 50001, RUNNO 1. It started at 20:00 and it is now 20:20.

```
fetch logs, from:now()-24h
```
Read all logs from the last 24 hours. Same as Splunk "Last 24 hours".

```
| filter contains(log.source, "daily_ctmag_", caseSensitive:false)
```
Keep only the Control-M agent daily log (`/opt/ctmhlx/ctm/dailylog/daily_ctmag_20261012.log`). This replaces `index="controlm*"`.

```
| filter contains(content, ") STARTED (") or contains(content, ") EXECUTION ENDED")
    or contains(content, ") ENDED OK") or contains(content, ") ENDED NOTOK")
```
Keep only start lines and end lines. Lines like `ACCEPTED` or `PING SUCCESSFULLY SENT` are dropped.

```
| parse content, "LD 'JOB ' NSPACE:job_name SPACE '(ORDERID ' INT:order_id ', RUNNO ' INT:run_no ')'"
```
Cut three values out of the text.

| Pattern piece | What it does |
|---|---|
| `LD 'JOB '` | Skip anything up to the word `JOB `. |
| `NSPACE:job_name` | Take the next word (no spaces) as `job_name`, for example `CLMB001`. |
| `SPACE '(ORDERID '` | Expect a space and then `(ORDERID `. |
| `INT:order_id` | Take the number as `order_id`, for example 50001. |
| `', RUNNO ' INT:run_no ')'` | Take the run number as `run_no`, for example 1. |

```
| fieldsAdd claims_jobs = array("CLAIMJOB01", "CLAIMJOB02")
| filter in(job_name, claims_jobs)
```
Keep only claims jobs. This replaces the Splunk lookup `[| inputlookup claims_jobs]`. The two names are placeholders. You must replace them.

```
| fieldsAdd is_start = contains(content, ") STARTED ("),
            is_end = contains(content, " ENDED")
```
Mark each line as a start line or an end line (true or false).

```
| summarize started = min(if(is_start, timestamp)),
            ended = max(if(is_end, timestamp)),
            host = takeFirst(host.name),
            by:{ job_name, order_id, run_no }
```
Squash all lines of one run into one row.

| Output | What it holds |
|---|---|
| `started` | Time of the start line. `if()` gives empty for end lines, and `min` ignores empties. |
| `ended` | Time of the end line, or empty if there is none yet. |
| `host` | The agent server that ran the job. |
| `by:{ job_name, order_id, run_no }` | One row per run, so a rerun is counted separately. |

Example result: `CLMB001, 50001, 1, started 20:00, ended (empty)`.

```
| filter isNotNull(started) and isNull(ended)
```
Keep runs that started but have not ended. A finished run (both times filled) is dropped here.

```
| fieldsAdd elapsed_min = toLong((now() - started) / 1m),
            starttime = formatTimestamp(started, format:"yyyy/MM/dd HH:mm:ss", timezone:"Asia/Tokyo")
```
Work out how many minutes it has been running (20:20 minus 20:00 = 20), and write the start time in Tokyo time for the email.

```
| filter elapsed_min >= 15
```
Only runs going 15 minutes or more. `CLMB001` at 20 minutes stays. A run at 10 minutes is dropped.

```
| fields job_name, order_id, run_no, starttime, elapsed_min, host
```
Keep only the columns worth showing on the problem.

### Part 5: Identity field

```hcl
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "job_name"
      }
```
Every minute the query returns `CLMB001` again while it is stuck. Because identity is `job_name`, Dynatrace keeps one problem open instead of making 1 problem per minute. This replaces the Splunk throttle idea.

### Part 6: Event template

| Property | Value | What it means |
|---|---|---|
| `event.type` | CUSTOM_ALERT | The problem is a custom alert. |
| `event.name` | Claim job over run | Headline on the problem. |
| `event.description` | Text | Body text shown on the problem and in the email. |
| `alert.severity` | medium | Read by the workflow to pick the route. |
| `app.name` | claims | Tag to find and filter problems. |
| `pagerduty.enabled` | 0 | Workflow sends email only, no page. |

`execution_settings {}` is empty and uses the defaults.

## Result

### A run's life in the alert

| Time | Log line | Query result | Problem |
|---|---|---|---|
| 20:00 | `JOB CLMB001 (ORDERID 50001, RUNNO 00001) STARTED` | Row with 0 minutes, dropped by the 15 minute filter | None |
| 20:15 | No new line | Row with 15 minutes, kept | Opens, email sent |
| 20:16 to 20:29 | No new line | Same job again | Same problem stays open |
| 20:30 | `... EXECUTION ENDED` | `ended` filled, row dropped | Closes |

### What to do before apply

| Step | Why |
|---|---|
| Replace `CLAIMJOB01` and `CLAIMJOB02` with the real list | Otherwise nothing ever matches. |
| Run check query 2 from answer 40 | Make sure the parse fills job_name, order_id and run_no. |
| Run check query 4 from answer 40 | Make sure 15 minutes is longer than a normal run. |
| `terraform validate` then `terraform plan` | Check the file before applying. |

## Data flow map

```
Control-M agent → daily_ctmag log
  "JOB CLMB001 (ORDERID 50001, RUNNO 00001) STARTED"
        │
        ▼
Dynatrace Grail logs
        │  detector runs every minute
        ▼
fetch 24 h → keep daily_ctmag → keep STARTED / ENDED lines
  → parse job_name, order_id, run_no → keep claims jobs
  → one row per run (started, ended)
  → no end and 15+ min → row survives
        │
        ▼
problem per job_name (medium) → workflow (pagerduty 0) → email
        │
ENDED line arrives → row gone → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `../40-claim-job-over-run-tf/40-claim-job-over-run-tf.tf` | The Terraform explained here. |
| `../40-claim-job-over-run-tf/40-claim-job-over-run-tf-check.dql` | Check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was explained. |
| `2-result.md` | Run life table and next steps. |
| `3-glossary.md` | Words used. |
| `41.sh` | Commands, one per line. |

## Commands

All commands are in [`41.sh`](./41.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/40-claim-job-over-run-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/41-claim-job-over-run-tf-explained
git commit -m "Explain claim job over run tf"
git push
```
