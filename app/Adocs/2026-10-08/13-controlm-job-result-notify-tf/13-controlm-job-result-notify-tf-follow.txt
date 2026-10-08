# Control-M Job Result Notify

## Decision tree

```
Splunk: CTL-M:ジョブ実行結果通知
 Step 1: activejobs that ended (Ended OK or Ended not OK) in the last 10 minutes
          skip job names ending -F or -S, skip empty names
 Step 2: dedup by run (order_id + isn)
 Step 3: did this run abend in the last 24 hours? (controlm_alert, message not empty)
          no  → drop
          yes → build TITLE and BODY in Japanese
                 Ended OK     → "<job> (<system>)正常終了 (<run>)[time]"
                 Ended not OK → "<job> (<system>)異常終了 (<run>:<対応方法>) [time]"
 Step 4: email To one person, CC per-job contact, throttle 10 min per job
Dynatrace: same steps in one Records query → 1 problem per run (UID), medium, no PagerDuty
 per-job CC? → detector cannot → route by app.name Control-M, or add a workflow later
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the alert mean? | A Control-M job that failed (abended) in the last 24 hours has just finished again, either OK (recovered) or not OK (failed again) |
| Who gets it? | One fixed person, plus the job's contact from controlm_SpecificContact.csv |
| One problem per | Control-M run (order_id plus isn) |
| How long is it open? | About 10 minutes after the job ends (the query keeps jobs that ended in the last 10 minutes) |
| Japanese title and body | Built the same way and kept as `TITLE` and `BODY` fields on the problem |
| Severity and PagerDuty | medium, `"0"` (email only, Normal) |
| Not possible in a detector | Per-job CC email |
| Replaces | 2026-10-07 seq 14 key `job_result_after_abend` |

## Summary

The alert tells operators the follow-up of an abend: did the job recover or fail again. The DQL follows the Splunk search step by step: jobs that ended in the last 10 minutes, deduplicated per run, kept only if the run abended in the last 24 hours, then the Japanese title and body are built. Each run becomes one problem.

## Splunk query line by line

| Splunk part | What it means | DQL |
|---|---|---|
| `sourcetype=controlm_activejobs` | Control-M job status snapshots | `matchesValue(log.source, "*controlm_activejobs*")` |
| `NOT (job_name="*-F" OR job_name="*-S") NOT job_name=""` | Skip helper jobs and empty names | `not endsWith(...)`, `job_name != ""` |
| `status="Ended OK" OR status="Ended not OK"` | Finished jobs only | Same condition |
| `where relative_time(now(),"-10m") < strptime(end_time,...)` | Ended in the last 10 minutes | `end_ts > now() - 10m` (end_time is JST text `yyyyMMddHHmmss`) |
| `eval UID=order_id+isn \| dedup UID` | One row per run | `fieldsAdd UID = concat(order_id, isn) \| dedup UID` |
| `join type=left order_id [ controlm_alert earliest=-24h ... ]` | Attach the abend from the last 24 hours | `lookup [ fetch logs, from:now()-24h ... ]` by order_id |
| `where message!=""` | Keep only runs that abended | `filter isNotNull(alert.message) and alert.message != ""` |
| `system=case(data_center=...)` | Open, MF#1, MF#3, or unknown | Nested `if` |
| `RUN_COUNT=case(application="NO_APPL", run_counter+1, ...)` | Run number shown in the title | Same `if` |
| `lookup controlm_addresslist.csv ... OUTPUT Method` | 対応方法 (how to respond) per job | `lookup [ load "/lookups/controlm/addresslist" ]` |
| `TITLE=case(...)`, `BODY=case(...)` | Japanese subject and message | `fieldsAdd TITLE = if(...)`, `BODY = if(...)` |
| `lookup controlm_SpecificContact.csv ... OUTPUT Email` | CC address per job | Not possible in a detector |
| Throttle `$result.JOB_CODE$` 10 minutes | One email per job per 10 minutes | Identity `UID` gives one problem per run |

## Terraform

File: `13-controlm-job-result-notify-tf.tf`. Key part of the query:

```
fetch logs, from:now()-30m
| filter matchesValue(log.source, "*controlm_activejobs*")
| filter isNotNull(job_name) and job_name != ""
| filter not endsWith(job_name, "-F") and not endsWith(job_name, "-S")
| filter status == "Ended OK" or status == "Ended not OK"
| fieldsAdd end_ts = toTimestamp(concat(<yyyy>, "-", <MM>, "-", <dd>, "T", <HH>, ":", <mm>, ":", <ss>, "+09:00"))
| filter end_ts > now() - 10m
| fieldsAdd UID = concat(order_id, isn)
| dedup UID
| lookup [ fetch logs, from:now()-24h | filter matchesValue(log.source, "*controlm_alert*") ... by:{ order_id } ], ...
| filter isNotNull(alert.message) and alert.message != ""
| ... TITLE, BODY ...
| fields UID, job_name, status, application, group_name, owner, odate, end_ts, TITLE, BODY
```

Identity: `UID`. Severity medium, `app.name = Control-M`, `pagerduty.enabled = "0"`.

## Data flow

```
Control-M → controlm_activejobs (job ended) + controlm_alert (abend in 24 h) → Grail
 → detector every minute
   → ended in last 10 min, not -F or -S, one row per run
   → abended in last 24 h? → yes → TITLE and BODY → 1 problem per run → email via standard flow
   → 10 min after end → row drops out → problem closes
```

## Investigation

| Screenshot | Finding |
|---|---|
| 1 | Same jenkins_statistics search as seq 12 (no new information) |
| 2 (search) | Full CTL-M:ジョブ実行結果通知 search shown above |
| 3 (settings) | `*/1`, Last 5 minutes, > 0, throttle on `$result.JOB_CODE$` 10 minutes, email To tadashi.yoshida, CC `$result.Email$`, Normal |
| Earlier versions | 2026-10-05 seq 31 (workflow) and 2026-10-07 seq 14 (Records, simplified) |

The email addresses were not copied into Terraform.

## Result

| Step | What to do |
|---|---|
| 1 | Run check queries 1 to 3 to confirm Control-M sources and fields |
| 2 | Upload `controlm_addresslist.csv` as `/lookups/controlm/addresslist` |
| 3 | Run query 4 to see how many problems per day to expect |
| 4 | If 2026-10-07 seq 14 was applied, remove its `job_result_after_abend` key first |
| 5 | If per-job CC is required, keep the 2026-10-05 seq 31 workflow for this alert instead |

## Related files

| File | Purpose |
|---|---|
| `13-controlm-job-result-notify-tf.tf` | Detector |
| `13-controlm-job-result-notify-tf-check.dql` | Check queries |
| `13.sh` | Commands |

## Commands

See `13.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/13-controlm-job-result-notify-tf"
terraform init
terraform validate
terraform plan
```
