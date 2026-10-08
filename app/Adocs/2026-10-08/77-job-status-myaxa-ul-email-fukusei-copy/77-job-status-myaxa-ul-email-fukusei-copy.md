# Job Status MyAXA UL Email Copy

## Decision tree

```
Job Status for MyAXA UL Email複製
 Search the same as seq 70 (dedup odate, OrderDate = yesterday)? → yes, line for line
 Cron 25 11 * * 1-6 vs seq 70's 30 11 * * 1-6                   → 5 minutes earlier, same days
 Recipient: one person (seq 70: team mail list)                  → personal test copy
 Subject "$result.MSG$ $name$"                                   → only the word order is swapped
 → do NOT migrate
 That person still wants the mail? → add them to the seq 70 route (app.name = "MyAXA UL")
 Want a separate detector anyway?  → optional tf: disabled, own resource name, low, PagerDuty "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| What is it? | A personal copy (複製 means "copy") of seq 70, "CHDE010MJob Status for MyAXA UL Email". |
| Is the logic different? | No. The search is identical. |
| What is different? | It runs at 11:25 instead of 11:30, mails one person, and puts MSG before the name in the subject. |
| Migrate it? | No. Seq 70 already raises the same problem. |
| What to do for the person | Add them to the notification route for `app.name = "MyAXA UL"`. |
| PagerDuty | "0" |

## Summary

This alert was cloned from the seq 70 alert, probably for testing, and sent to a single person. Dynatrace needs only one detector per real check, so seq 70 stays the only one. The optional tf is provided disabled, with its own resource name, so it can never clash with seq 70.

## Investigation

| What I compared | Seq 70 | This copy |
|---|---|---|
| Search | dedup odate, OrderDate = yesterday, MSG OK or 要確認 | Same |
| Cron | `30 11 * * 1-6` | `25 11 * * 1-6` |
| Time range | Last 1 day | Last 1 day |
| Trigger | Results > 0, for each result, no throttle | Same |
| Recipients | Team mail list (not copied) | One person (not copied) |
| Priority | Normal | Normal |
| Subject | `$name$ $result.MSG$` | `$result.MSG$ $name$` |
| Message | Run-day explanation (weekly and monthly data days) | Same |
| Include | Link to alert, inline table | Same, plus Allow Empty Attachment |

## Result

| Item | Value |
|---|---|
| Recommendation | Do not migrate. Retire it at Splunk cut-over. |
| Optional resource | `chde010m_myaxa_ul_job_status_copy` |
| Enabled | false |
| Severity | low |
| Time gate in optional tf | 11:25 JST, Monday to Saturday, matching the copy's cron |
| Conflict with seq 70 | None. It has a different resource name. |

## Data flow map

```
CHDE010M (controlm_activejobs)
  → seq 70 detector (yesterday's odate, Mon-Sat from 11:30, not Ended OK) → problem (medium)
      → route app.name "MyAXA UL" → team list (+ this copy's person if wanted)
  → 複製 alert → not migrated (optional disabled copy only)
```

## Related files

| File | What it is |
|---|---|
| `77-job-status-myaxa-ul-email-fukusei-copy-optional.tf` | Optional disabled detector |
| `77-job-status-myaxa-ul-email-fukusei-copy-check.dql` | Latest CHDE010M status for each order date over 7 days |
| `77-job-status-myaxa-ul-email-fukusei-copy.spl` | Confirms the search hash matches seq 70 and shows when the copy last fired |
| `77.sh` | Commands |

## Commands

These are in `77.sh`. Nothing has been run. Only apply if you really want the copy.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/77-job-status-myaxa-ul-email-fukusei-copy"
terraform init
terraform validate
terraform plan
```
