# Splunk Cron And Expires Explained

## Decision Tree

```
Splunk alert settings in the screenshot
 Cron Expression "0 8 * * *" → WHEN the search runs → every day at 08:00 (search head time zone)
 Time Range "Today"          → WHAT period it searches → midnight to run time
 Expires "24 hour(s)"        → HOW LONG the fired alert record is kept → 24 hours, then deleted
Moving to Dynatrace?
 detector (seq 43) → no cron (runs every minute), no expires (problem closes by rule)
 workflow (seq 42) → cron "0 8 * * *" + time_zone Asia/Tokyo, no expires needed
```

## Short Takeaway

| Question | Answer |
|---|---|
| What does `0 8 * * *` mean? | Run at minute 0 of hour 8, every day, every month, every weekday: daily at 08:00 |
| Which time zone? | The Splunk server's time zone, not necessarily yours. Confirm it is JST |
| What does Expires 24 hours mean? | The triggered alert entry and its search results are kept for 24 hours, then removed |
| Does Expires affect when it runs? | No. It only controls how long the result is kept after it fires |
| Dynatrace detector equivalent | No cron and no expires: it checks every minute and the problem closes by itself |

## Summary

The cron line decides when Splunk runs the search: every day at 08:00. "Today" decides how far back it looks: from midnight. Expires is only housekeeping: after the alert fires, Splunk keeps the triggered alert and its results for 24 hours, then deletes them. It does not change when or whether the alert fires or the email is sent.

## Cron: The Five Fields

`0 8 * * *`

| Position | Field | Value here | What it means |
|---|---|---|---|
| 1 | Minute | `0` | At minute 0 |
| 2 | Hour | `8` | At 8 o'clock (24-hour clock) |
| 3 | Day of month | `*` | Every day of the month |
| 4 | Month | `*` | Every month |
| 5 | Day of week | `*` | Every day of the week |

Result: once a day at 08:00.

## Other Cron Examples From Today's Alerts

| Cron | Plain meaning | Seen in |
|---|---|---|
| `*/1 * * * *` | Every minute | Jenkins URL checks, EIP MQ timeout |
| `*/5 * * * *` | Every 5 minutes | AGPO Auth0 error |
| `*/10 * * * *` | Every 10 minutes | Claims Auto-Assessment, HTTP outlier |
| `30 11 * * 2-6` | 11:30 on Tuesday to Saturday | MyAXA UL job status (seq 31) |
| `0 8 * * *` | 08:00 every day | Datalake Batch Result |

## Cron And Time Range Work Together

| Setting | Role | In this alert |
|---|---|---|
| Cron | When the search starts | 08:00 |
| Time Range | Which data it reads | "Today": 00:00 to 08:00 |
| Trigger condition | When it counts as fired | More than 0 results |
| Action | What happens when fired | Email to masayuki.yasuda |

## Time Zone Trap

| Point | What it means |
|---|---|
| Splunk cron uses the search head's system time zone | If the server is in UTC, `0 8 * * *` is 17:00 JST |
| "Today" uses the alert owner's time zone setting | Midnight may differ from the cron's clock |
| How to confirm | Look at "Next Scheduled Time" in Splunk, or the run times in the scheduler log (`index=_internal sourcetype=scheduler savedsearch_name="Datalake_Batch Result"`) |

## Expires: What It Does

| Point | What it means |
|---|---|
| What is kept | The triggered alert entry (Activity → Triggered Alerts) and the search job results behind it |
| How long | 24 hours after the alert fires |
| After that | The entry and results are deleted from Splunk |
| What it does not do | Does not stop the email, change the schedule, or suppress repeats (that is Throttle) |
| Why 24 hours here | Daily alert, so each result lives until the next day's run |

## Expires vs Throttle

| Setting | Controls | Example |
|---|---|---|
| Expires | How long the fired result is stored | Keep for 24 hours |
| Throttle | Whether repeat alerts are suppressed | Do not fire again for 1 hour |

## How These Map To Dynatrace

| Splunk setting | Dynatrace detector (seq 43) | Dynatrace workflow (seq 42) |
|---|---|---|
| Cron `0 8 * * *` | None; the detector runs every minute | `trigger { schedule { cron = "0 8 * * *", time_zone = "Asia/Tokyo" } }` |
| Time Range Today | Sliding window of 5 minutes | `fetch logs, from:now()-8h` |
| Expires 24 hours | None; the problem stays open until 60 quiet minutes, then closes and stays in history | None; each execution is kept in workflow history |
| Throttle | `dealertingSamples` keeps one problem open instead of repeats | Not needed; runs once a day |

Note: the Dynatrace workflow cron has an explicit `time_zone`, so `0 8 * * *` with `Asia/Tokyo` is always 08:00 JST. Splunk has no such field per alert.

## Data Flow

```
Splunk:
 08:00 (cron, server TZ) → search "Today" → results > 0 ? → email
                                                    → triggered alert kept 24 h (Expires) → deleted
Dynatrace detector:
 every minute → count lines → > 0 → problem → closes after 60 quiet minutes → history
Dynatrace workflow:
 08:00 Asia/Tokyo → query since 00:00 JST → lines > 0 → email
```

## Investigation

| Checked | Evidence |
|---|---|
| Screenshot cron | `0 8 * * *` |
| Screenshot time range | Today |
| Screenshot expires | 24 hour(s) |
| Throttle | Off |
| Seq 42 workflow | cron `0 8 * * *`, time_zone Asia/Tokyo |
| Seq 43 detector | No schedule field; window 5, dealerting 60 |

## Result

| Step | What to do |
|---|---|
| 1 | Check Splunk "Next Scheduled Time" to confirm 08:00 is JST |
| 2 | If you need the 08:00 timing, use the seq 42 workflow; the seq 43 detector cannot schedule |
| 3 | Ignore Expires during migration; Dynatrace keeps problem and workflow history on its own |

## Related Files

| File | Purpose |
|---|---|
| `42-datalake-batch-result-tf/42-datalake-batch-result-tf.tf` | Workflow version with cron |
| `43-datalake-batch-result-detector/43-datalake-batch-result-detector.tf` | Detector version without cron |
| `45.sh` | Commands |

## Commands

See `45.sh`. Splunk search to see real run times:

```
index=_internal sourcetype=scheduler savedsearch_name="Datalake_Batch Result" | table _time scheduled_time status result_count
```
