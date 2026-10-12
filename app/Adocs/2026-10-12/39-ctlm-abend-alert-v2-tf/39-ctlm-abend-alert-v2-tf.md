# Control-M Abend Alert V2

## Decision tree

```
Splunk: sourcetype=controlm_alert message="Ended not OK" + eval + join
 sourcetype → no Dynatrace match → content contains "Ended not OK"
 Splunk auto fields → parse each key from content
   check query 1 shows a different format? → change the parse patterns
 eval system, RUN_COUNT, JOB_CODE, HH, MM, SS → fieldsAdd with if(), concat(), substring()
 join with controlm_def_ver_jobs → left out of detector (heavy, only adds owner and cmd_line)
 Last 5 minutes → from:now()-5m
 more than 0, for each result → no summarize
 throttle by JOB_CODE 6 min → identity JOB_CODE
 actions not visible → high, PagerDuty 0 until confirmed
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it catch? | Every Control-M job that ended not OK (abend) in the last 5 minutes. |
| One problem per? | `JOB_CODE`, which is job name plus run time. Each abend alerts once. |
| Main risk | The parse lines assume `key=value` text. Check query 1 confirms the real format. |
| Join | Owner and command line lookup is not in the detector. Check query 4 shows how. |
| Severity | high, PagerDuty off. The actions part was cut off in the screenshot. |

## Summary

The Splunk search picks Control-M abend messages, builds extra fields, and joins job definitions for the owner and command line. In Dynatrace the fields have to be parsed from the log text, and the throttle on `JOB_CODE` becomes the identity field. The join is optional decoration, so it stays out of the every-minute detector.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Control-M | BMC's job scheduler. It runs batch jobs on open systems and the mainframe. | The source of the alert. |
| Abend | "Abnormal end". The job failed. Control-M shows it as "Ended not OK". | This is what the alert is for. |
| `eval` | Splunk command that creates new fields. | Becomes `fieldsAdd` in DQL. |
| `parse` | DQL command that pulls a value out of the log text. | Splunk extracted the fields for you. Dynatrace needs it spelled out. |
| `join type=left` | Add matching columns from another search, keep rows that have no match. | Same idea as DQL `join ... kind:leftOuter`. |
| Throttle by field | Splunk skips repeats with the same field value for a time. | Dynatrace does this with the identity field. |

### Splunk to Dynatrace

| Splunk piece | Dynatrace form |
|---|---|
| `sourcetype=controlm_alert` | No match. Content filter only. Add `log.source` after check query 2. |
| `message="Ended not OK"` | `contains(content, "Ended not OK", caseSensitive:false)` |
| Auto fields (job_name, data_center and the rest) | One `parse content, "LD 'key=' NSPACE:key"` per field. |
| `system=case(data_center="Server#1","Open", data_center="mainframe#1","MF", true(),"unknown")` | Nested `if()`. |
| `RUN_COUNT=case(application="NO_APPL", run_counter+1, true(), run_counter)` | `if(application == "NO_APPL", run_counter + 1, else: run_counter)` |
| `JOB_CODE=job_name+current_time` | `concat(job_name, current_time)` |
| `HH=substr(current_time,9,2)` | `substring(current_time, from:8, to:10)`. Splunk counts from 1, DQL from 0. |
| `MM=substr(current_time,11,2)` | `substring(current_time, from:10, to:12)` |
| `SS=substr(current_time,13,2)` | `substring(current_time, from:12, to:14)` |
| `table ...` | `fields ...` |
| `join type=left job_name [controlm_def_ver_jobs]` | Left out. Check query 4 has a DQL `join`. |
| `fields - _raw` | Not needed. `content` is kept so the problem shows the line. |
| Last 5 minutes, cron every minute | `from:now()-5m`. |
| More than 0, for each result | Detector default, no `summarize`. |
| Throttle `JOB_CODE`, 6 minutes | Identity `JOB_CODE`. The same abend seen in overlapping windows stays one problem. |
| Actions | Not visible in the screenshot. Set to high, PagerDuty off. No recipients copied. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "ctlm_abend_alert_v2" {
  title       = "CTL-M アベンドアラートV2"
  description = "Control-M job ended not OK (abend). One problem per JOB_CODE (job_name plus current_time), so each abend alerts once."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(content, "Ended not OK", caseSensitive:false)
          | parse content, "LD 'job_name=' NSPACE:job_name"
          | parse content, "LD 'data_center=' NSPACE:data_center"
          | parse content, "LD 'application=' NSPACE:application"
          | parse content, "LD 'run_counter=' INT:run_counter"
          | parse content, "LD 'current_time=' NSPACE:current_time"
          | parse content, "LD 'memname=' NSPACE:memname"
          | parse content, "LD 'group_name=' NSPACE:group_name"
          | parse content, "LD 'node_id=' NSPACE:node_id"
          | filter isNotNull(job_name)
          | fieldsAdd system = if(data_center == "Server#1", "Open",
                                else: if(data_center == "mainframe#1", "MF", else: "unknown")),
                      RUN_COUNT = if(application == "NO_APPL", run_counter + 1, else: run_counter),
                      JOB_CODE = concat(job_name, current_time),
                      HH = substring(current_time, from:8, to:10),
                      MM = substring(current_time, from:10, to:12),
                      SS = substring(current_time, from:12, to:14)
          | fields timestamp, JOB_CODE, HH, MM, SS, RUN_COUNT, system, job_name, application,
                   data_center, group_name, memname, node_id, host.name, content
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "JOB_CODE"
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
        value = "Control-M job abend"
      }
      property {
        key   = "event.description"
        value = "A Control-M job ended not OK. See job_name, system, RUN_COUNT and HH:MM:SS on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "controlm"
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
| Check query 1 | Shows the real line format. If it is `job_name: X` instead of `job_name=X`, change every `'key='` to `'key: '`. If it is JSON, use `parse content, "JSON:j"` and `j[job_name]`. |
| Check query 2 | Finds the host and `log.source`, so you can add a source filter like the Splunk sourcetype. |
| Check query 3 | Every row should have `job_name` and `current_time`. Empty values mean the pattern is wrong. |
| Check query 4 | Shows how to add owner and cmd_line if the team needs them on the alert. |
| Actions | Scroll down on the Splunk screen. If it pages or uses High priority with PagerDuty, set `pagerduty.enabled = "1"`. |

## Data flow map

```
Control-M job ends not OK
  → Control-M writes an alert line (message="Ended not OK")
  → Dynatrace Grail logs
  → detector every minute, last 5 min
       parse job_name, data_center, run_counter, current_time and the rest
       build system, RUN_COUNT, JOB_CODE, HH, MM, SS
  → one problem per JOB_CODE (high)
  → workflow: pagerduty.enabled = "0" → email
  → line older than 5 min → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `39-ctlm-abend-alert-v2-tf.tf` | Full Terraform. |
| `39-ctlm-abend-alert-v2-tf-check.dql` | Four check queries, including the optional join. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `39.sh` | Commands, one per line. |

## Commands

All commands are in [`39.sh`](./39.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/39-ctlm-abend-alert-v2-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/39-ctlm-abend-alert-v2-tf
git commit -m "Control-M abend alert V2 detector"
git push
```
