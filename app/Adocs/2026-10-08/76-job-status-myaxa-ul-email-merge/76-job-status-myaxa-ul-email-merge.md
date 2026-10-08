# Job Status MyAXA UL Email Merge

## Decision tree

```
Job Status for MyAXA UL Email (CHDE010M, 11:30 Tue-Sat)
 same job as seq 70 (CHDE010MJob Status for MyAXA UL Email)? → yes, CHDE010M
 same To list, same 11:30, same Normal priority?             → yes
 days 2-6 inside seq 70's 1-6?                              → yes
 difference → no order-date filter (latest record of last day) vs seq 70 yesterday's odate
   real failure of yesterday's run → seq 70 already opens a problem
   today's run still executing at 11:30 → this alert would say 要確認 (false alarm), seq 70 would not
 → merge into seq 70, do NOT migrate separately
 still want it? → optional tf: disabled, own resource name, medium, pd 0
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | It is a second Splunk alert for the same job as seq 70. |
| Migrate it separately? | No. Seq 70 already covers every real failure it would mail. |
| What is the difference? | It looks at the latest CHDE010M record of the last day. Seq 70 looks at yesterday's order date. |
| Which is better? | Seq 70. It does not flag a run that belongs to today and may still be running. |
| If you want it anyway | Use the optional tf. It is disabled, with its own resource name. |
| PagerDuty | "0" |

## Summary

Splunk has two mails for CHDE010M at 11:30 to the same people. "CHDE010MJob Status for MyAXA UL Email" (seq 70) checks yesterday's order date. "Job Status for MyAXA UL Email" checks whatever the latest record is. Seq 70 is the stricter and safer of the two, so one Dynatrace detector is enough. 10-05 seq 31 reached the same conclusion and merged them.

## Investigation

| What I compared | Seq 70 alert | This alert |
|---|---|---|
| Job | CHDE010M | CHDE010M |
| Which record | Latest record of yesterday's order date (`dedup odate`, OrderDate = yesterday) | Latest record of the last day (`dedup job_name`) |
| MSG when not OK | 正常終了していません要確認 | 正常終了していません要確認 |
| Days | Monday to Saturday | Tuesday to Saturday (`30 11 * * 2-6`) |
| Time | 11:30 JST | 11:30 JST |
| Time range | Last 1 day | Last 1 day |
| Recipients | MyAXA UL mail list (not copied) | Same list (not copied) |
| Priority | Normal | Normal |
| Subject | `$name$ $result.MSG$` | `$name$ $result.MSG$` |

In Dynatrace, recipients are set where problems are routed, not in the detector. If this alert's recipient list has anyone extra, add them to the seq 70 route instead of creating a second detector.

## Result

| Item | Value |
|---|---|
| Recommendation | Merge into seq 70. Do not migrate separately. |
| Action for routing | Compare recipients with the `.spl` first line. Add any extra address to the route for `app.name = "MyAXA UL"` |
| Optional resource | `chde010m_job_status_myaxa_ul_latest`, `enabled = false`, medium, pagerduty "0" |
| Conflict with seq 70 | None. It has a different resource name. |
| Splunk clean-up | Retire this alert together with the seq 70 one at cut-over |

## Data flow map

```
CHDE010M (controlm_activejobs)
  → seq 70 detector: yesterday's odate, Mon-Sat from 11:30, not Ended OK → problem (medium)
      → route app.name "MyAXA UL" → MyAXA UL mail list
  → this alert: covered by seq 70 → not migrated (optional disabled copy only)
```

## Related files

| File | What it is |
|---|---|
| `76-job-status-myaxa-ul-email-merge-optional.tf` | Optional, disabled detector (latest record logic) |
| `76-job-status-myaxa-ul-email-merge-check.dql` | Same checks as seq 70 |
| `76-job-status-myaxa-ul-email-merge.spl` | Both alerts' recipients, and the days each one fired |
| `76.sh` | Commands |

## Commands

These are in `76.sh`. Nothing has been run. Only apply if you really want the separate copy.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/76-job-status-myaxa-ul-email-merge"
terraform init
terraform validate
terraform plan
```
