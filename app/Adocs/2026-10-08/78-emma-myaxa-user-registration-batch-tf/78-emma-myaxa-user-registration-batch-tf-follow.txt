# Emma MyAXA User Registration Batch

## Decision tree

```
Prod_Life_Emma_MyAXAUserRegistrationBatchStatus_Normal (CHDR010M, every day 06:00)
 Latest CHDR010M record in the last day
   Ended OK      → nothing (Splunk sent an "OK" status mail; no Dynatrace problem)
   anything else → problem (medium), one per order date
 Problem open, what next?
   status Ended not OK → check the Control-M log, rerun the job
   status Executing    → batch running late, check after it ends
 Already applied 10-07 seq 14 chdr010m_no_success? → remove that key, this replaces it
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the Splunk alert do? | Every morning at 06:00 it emails the latest status of CHDR010M, the emma registration batch. |
| What does Dynatrace do? | It opens a problem only when the latest status is not Ended OK. |
| Resource | `chdr010m_emma_user_registration_status` |
| Severity | medium (email priority Normal) |
| PagerDuty | "0" (no PagerDuty action on the screenshot) |
| Replaces | 10-07 seq 14 `chdr010m_no_success` |
| To confirm | The Splunk time range is not visible, so 1 day is assumed. |

## Summary

The Splunk alert is a daily status report: it always has a result, so it mails every day. In Dynatrace, only the useful case becomes a problem: the latest CHDR010M run is not Ended OK. The detector uses the same "latest record" pattern as seq 70 and seq 73, and it is more precise than the coarse 26-hour check in 10-07 seq 14.

## Investigation

| What I checked | What I found |
|---|---|
| Search | CHDR010M, `dedup job_name` (latest record), StartTime and EndTime formatted |
| Status filter in Splunk | None. Every run is reported. |
| Schedule | Run every day at 6:00 |
| Time range | Not visible on the screenshot |
| Trigger | Results > 0, once, for each result, no throttle |
| Actions | Add to Triggered Alerts, and Send email with priority Normal |
| PagerDuty | No PagerDuty action |
| Earlier answers | 10-05 seq 31 listed "CHDR010MJob Status for MyAXA User Registration Batch" at 06:00 for the same job. 10-07 seq 14 made it `chdr010m_no_success`. |

## Result

| Item | Value |
|---|---|
| Detector | Records detector, `fetch logs, from:now()-1d` |
| Fires when | The latest CHDR010M record is not Ended OK, from 06:00 JST |
| Identity | `job_name` and `odate`, so each order date gets one problem |
| Clean-up | Remove `chdr010m_no_success` from the 10-07 seq 14 `controlm_alerts` map if it was applied |
| Not detected | A day with no CHDR010M record at all. The Splunk alert does not catch that either. |

## Data flow map

```
Control-M CHDR010M
  → controlm_activejobs logs in Grail
  → detector (every minute, gated from 06:00 JST)
      latest record per job_name in last 1 day
      status != "Ended OK" → problem (medium, app.name "MyAXA emma")
  → notification route → email list (not copied), PagerDuty off
```

## Related files

| File | What it is |
|---|---|
| `78-emma-myaxa-user-registration-batch-tf.tf` | The detector |
| `78-emma-myaxa-user-registration-batch-tf-check.dql` | Run times, field formats, dry run |
| `78-emma-myaxa-user-registration-batch-tf.spl` | Splunk time range and severity, run history, fire history |
| `78.sh` | Commands |

## Commands

These are in `78.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/78-emma-myaxa-user-registration-batch-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
