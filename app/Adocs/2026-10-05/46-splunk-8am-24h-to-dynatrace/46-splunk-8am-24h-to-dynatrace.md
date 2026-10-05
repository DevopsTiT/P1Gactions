# Splunk 8am And 24h In Dynatrace

## Decision Tree

```
Splunk: run at 08:00 every day, Expires 24 hours
 Need the alert to happen exactly at 08:00?
   yes → needs a schedule → only a Dynatrace workflow has one (seq 42)
   no  → detector is fine (seq 43): alerts when the lines appear
 Need "24 hours" in Dynatrace?
   Expires is only Splunk's record retention → nothing to copy
   Dynatrace keeps problem and workflow history by itself
```

## Short Takeaway

| Question | Answer |
|---|---|
| What does "8 every time" do in Splunk? | Starts the search at 08:00 each day |
| What does "Expires 24 hours" do? | Keeps the fired alert record and results for 24 hours, then deletes them |
| Can a Dynatrace detector run at 08:00? | No. A detector has no schedule; it checks every minute |
| Can a detector stay open exactly 24 hours? | No. It closes by a rule (quiet minutes), not by a clock |
| Do you need to copy Expires? | No. It is housekeeping, not alert logic |
| If 08:00 matters | Use the seq 42 workflow; it is the only Dynatrace object with a cron |

## Summary

The two Splunk settings are not alert logic you must rebuild. The 08:00 cron only exists because Splunk alerts are scheduled searches; Dynatrace detectors watch continuously instead. Expires is Splunk storage cleanup. So the detector in seq 43 is a valid "alert only" conversion. The only reason to keep a schedule is if the team really wants one notice at 08:00, and then a workflow is required.

## Splunk Setting vs Dynatrace

| Splunk setting | What it really does | Dynatrace detector (seq 43) | Dynatrace workflow (seq 42) |
|---|---|---|---|
| Cron `0 8 * * *` | When the search runs | Not available; runs every minute | `cron = "0 8 * * *"`, `time_zone = "Asia/Tokyo"` |
| Time Range Today | How far back it reads | Last 5 minutes, every minute | `from:now()-8h` (since 00:00 JST) |
| Results > 0 | When it fires | Count above 0 | Email only if lines exist |
| Expires 24 hours | Keep the fired record 24 hours | Not needed; problem history kept | Not needed; execution history kept |

## What Changes If You Keep The Detector

| Topic | Splunk | Detector |
|---|---|---|
| Notice time | Once at 08:00 | When the batch writes lines (for example 02:15) |
| Number of notices | 1 per day | 1 per batch run (60 quiet minutes closes it) |
| Content | List of today's lines | Problem title and description; lines in the Logs app |
| Record lifetime | 24 hours | Problem stays in Dynatrace history |

## Which To Choose

| If the team says | Use |
|---|---|
| "We just need to know when the batch wrote something" | Detector, seq 43 |
| "We read one summary every morning at 8" | Workflow, seq 42 |
| "We need the lines in the message" | Workflow, seq 42 |

## Data Flow

```
Splunk:   08:00 → search Today → results > 0 → email → record kept 24 h
Detector: every minute → lines > 0 → problem → closes after 60 quiet minutes
Workflow: 08:00 JST → query since 00:00 JST → lines > 0 → email
```

## Investigation

| Checked | Evidence |
|---|---|
| Splunk screenshot | Cron `0 8 * * *`, Time Range Today, Expires 24 hours, Throttle off |
| Detector Terraform schema | Inputs are query, threshold, condition, samples and window; no schedule field |
| Workflow Terraform schema | `trigger.schedule.trigger.cron` and `time_zone` exist |

## Result

| Step | What to do |
|---|---|
| 1 | Ask the email owner whether the 08:00 timing matters |
| 2 | If no, keep seq 43 detector |
| 3 | If yes, use seq 42 workflow |
| 4 | Ignore Expires in either case |

## Related Files

| File | Purpose |
|---|---|
| `43-datalake-batch-result-detector/43-datalake-batch-result-detector.tf` | Detector version |
| `42-datalake-batch-result-tf/42-datalake-batch-result-tf.tf` | Scheduled workflow version |
| `46.sh` | Commands |

## Commands

See `46.sh`.
