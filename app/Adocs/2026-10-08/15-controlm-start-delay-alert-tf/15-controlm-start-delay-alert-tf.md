# Control-M Start Delay Alert TF

## Decision tree

```
Control-M job starts late
 controlm_alert log line contains "Start Time Delay"?
   no  -> nothing happens
   yes -> enrich with 3 lookups (addresslist, job_definition, specific_contact)
          -> build JOB_CODE = job_name + current_time
          -> one Dynatrace problem per JOB_CODE
             SpecificContact has TITLE/BODY? -> use them as MailTitle/MailBody
             no                              -> build the default Splunk-style text
 No problems ever open?
   -> run check.dql query 1 (do delay events reach Grail?)
   -> query 3 (are the lookups uploaded with a job_name column?)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the alert do? | Sends one email per Control-M job whose start time is delayed. |
| Which Dynatrace analyzer? | Records detector, one row per delay event. |
| What groups the problems? | `JOB_CODE`, which is job name plus the alert time, so each delay event is its own problem. |
| Severity | medium (Splunk priority not shown, treated as Normal). |
| PagerDuty | "0", because Splunk only sends email. |
| What can't be copied? | The "Output results to lookup" history file, and the per-job CC email. |

## Summary

The Splunk alert watches `controlm_alert` events containing "Start Time Delay" every 2 minutes and emails a Japanese-style title and body built from three CSV lookups. The Dynatrace version runs the same filter over the last 5 minutes, joins the same three lookups, rebuilds `MailTitle` and `MailBody`, and opens one problem per `JOB_CODE`.

## Splunk to Dynatrace mapping

| Splunk piece | What it means | Dynatrace |
|---|---|---|
| `sourcetype=controlm_alert "Start Time Delay"` | Control-M delay events | `matchesValue(log.source, "*controlm_alert*")` plus `contains(content, "Start Time Delay")` |
| `join controlm_addresslist.csv` | Adds Method, Main, Sub for each job | `lookup [ load "/lookups/controlm/addresslist" ]`, prefix `addr.` |
| `join controlm_job_Definition.csv` | Adds CMD_STRING, node_id, owner | `lookup [ load "/lookups/controlm/job_definition" ]`, prefix `def.` |
| `join controlm_SpecificContact.csv` | Adds per-job Email, TITLE, BODY | `lookup [ load "/lookups/controlm/specific_contact" ]`, prefix `sc.` |
| `system=case(data_center=...)` | Server#1 is Open, mainframe#1 is MF#1, mainframe#3 is MF#3 | Nested `if()` |
| `JOB_CODE=job_name+current_time` | Unique key per delay event | Same, and used as the alert identity |
| `HH, MM, SS = substr(current_time, ...)` | Time part of `yyyyMMddHHmmss` | `substring(current_time, from:8, to:14)` split into HH:MM:SS |
| `RunInfo` | APL- jobs show run count and Method (or 未登録); other jobs show run count + 1 | `if(startsWith(application, "APL-"), ...)` |
| `MailTitle`, `MailBody` | Use the SpecificContact text if it exists, otherwise a default text | Same logic with `if(isNotNull(...))` |
| Last 5 minutes, cron */2 | Look back 5 minutes every 2 minutes | `from:now()-5m`; the detector runs every minute |
| Trigger For each result | One alert per row | Identity `JOB_CODE` |
| Throttle JOB_CODE 5 minutes | Don't repeat the same event | Same JOB_CODE keeps the same open problem |
| Output results to lookup `controlmalertabendhistory2.csv` | Keeps a history file | Not possible in a detector; the history is already in Grail logs |
| Send email | Email action | Your Dynatrace notification workflow, routed by `app.name = Control-M` |

## Terraform

See `15-controlm-start-delay-alert-tf.tf` (full file is also in the chat answer).

Key query:

```
fetch logs, from:now()-5m
| filter matchesValue(log.source, "*controlm_alert*")
| filter contains(content, "Start Time Delay", caseSensitive:false)
| lookup [ load "/lookups/controlm/addresslist" ], sourceField:job_name, lookupField:job_name, prefix:"addr."
| lookup [ load "/lookups/controlm/job_definition" ], sourceField:job_name, lookupField:job_name, prefix:"def."
| lookup [ load "/lookups/controlm/specific_contact" ], sourceField:job_name, lookupField:job_name, prefix:"sc."
| fieldsAdd system, RUN_COUNT, JOB_CODE, HMS, RunInfo, MailTitle, MailBody
| dedup JOB_CODE
| fields timestamp, JOB_CODE, job_name, system, ..., MailTitle, MailBody
```

Identity: `alertIdentityFields[0] = JOB_CODE`.

## Data flow

```
Control-M server
  -> controlm_alert log ("Start Time Delay")
  -> Dynatrace Grail logs
  -> Records detector (every minute, last 5 min)
       + addresslist       (Method, Main, Sub)
       + job_definition    (CMD_STRING, node_id, owner)
       + specific_contact  (Email, TITLE, BODY)
  -> one row per JOB_CODE
  -> Davis problem "Control-M 遅延アラート" (medium, app Control-M, pagerduty 0)
  -> notification workflow -> email
```

## Investigation

| What I checked | What I found |
|---|---|
| Search text | Base filter is `sourcetype=controlm_alert "Start Time Delay"`, with three left joins. |
| The addresslist lookup | Splunk renames `JobID` to `job_name`. The Dynatrace lookup must have a `job_name` column, or change `lookupField` to `JobID`. |
| current_time format | `substr(current_time, 9, 2)` is HH, so the format is `yyyyMMddHHmmss`. DQL substring starts at 0, so HH is `from:8, to:10`. |
| Trigger | More than 0 results, For each result, throttle on JOB_CODE for 5 minutes. |
| Actions | Output to lookup `controlmalertabendhistory2.csv` (append) and Send email. No PagerDuty. |
| Seq 13 | The same three lookups and `system` mapping were used for the job result alert, so the lookup paths are shared. |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1. If it returns nothing, delay events don't reach Dynatrace yet. Fix ingestion first. |
| 2 | Run query 2. If `job_name` or `current_time` are not attributes, add a parse step or a log processing rule. |
| 3 | Run query 3. Upload any missing lookup, with a `job_name` column. |
| 4 | Run `terraform plan`, then `terraform apply` from `15.sh`. |
| 5 | If someone reads `controlmalertabendhistory2.csv`, give them a notebook query over Grail instead. |

## Related files

| File | What it is |
|---|---|
| `15-controlm-start-delay-alert-tf.tf` | The detector |
| `15-controlm-start-delay-alert-tf-check.dql` | Queries to confirm data and lookups |
| `15.sh` | Commands, one per line |
| `../13-controlm-job-result-notify-tf/` | Sister alert using the same lookups |

## Commands

Commands are in `15.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/15-controlm-start-delay-alert-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
