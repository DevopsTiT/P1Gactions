# PDDW0100 Status Copy

## Decision tree

```
Claims Status Service PDDW0100 Status複製 (複製 = copy)
 search same as production (seq 73)? → yes, line for line
 schedule same?                      → yes, 08:15 daily, last 24 h, expires 1 h
 actions?                            → not visible (10-05 seq 31: personal copy)
 → copy → do NOT migrate (production seq 73 already covers it)
 still want it?                      → optional tf: own resource name, enabled = false, low, pd 0
 cut-over                            → ask the owner to delete the Splunk 複製 alert
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a real alert? | No. It is a copy of PDDW0100 Status. 複製 means "copy". |
| What is different from production? | Only the title. The actions are not visible in this screenshot. |
| Migrate it? | No. Seq 73 already watches the same runs. |
| If you want it anyway | Use the optional tf. It is disabled, low severity, with its own resource name. |
| PagerDuty | "0" |

## Summary

This is the third PDDW0100 alert with the same search: production (seq 73), `_test` (seq 74) and this `複製`. Only production should move to Dynatrace. The two copies would only add duplicate problems.

## Investigation

| What I compared | Production (seq 73) | 複製 |
|---|---|---|
| Search | PDDW*, latest snapshot per run, Ended OK, claims_job_list lookup | Same |
| Schedule | `15 8 * * *`, last 24 hours | Same |
| Expires | 1 hour | Same |
| Trigger | Results greater than 0, once, for each result | Same |
| Actions | Email to the business team, priority Highest | Not visible. 10-05 seq 31 recorded it as a personal copy. |

## Result

| Item | Value |
|---|---|
| Recommendation | Do not migrate |
| Optional resource | `pddw0100_claims_status_copy` |
| Optional state | `enabled = false`, severity low, pagerduty "0" |
| Conflict | None with seq 73 or seq 74. Each has its own resource name. |
| Splunk clean-up | Ask the owner to delete or disable the 複製 alert at cut-over |

The three PDDW0100 alerts:

| Splunk alert | Migrate? | Folder |
|---|---|---|
| Claims Status Service PDDW0100 Status | Yes | seq 73 |
| Claims Status Service PDDW0100 Status_test | No | seq 74 (optional, disabled) |
| Claims Status Service PDDW0100 Status複製 | No | seq 75 (optional, disabled) |

## Data flow map

```
PDDW runs → production PDDW0100 detector (seq 73) → problem per unfinished run → email route
         ↘ _test copy (seq 74) → not migrated
         ↘ 複製 copy (seq 75)  → not migrated
```

## Related files

| File | What it is |
|---|---|
| `75-pddw0100-status-fukusei-copy-optional.tf` | Optional, disabled copy detector |
| `75-pddw0100-status-fukusei-copy-check.dql` | Same checks as seq 73 |
| `75-pddw0100-status-fukusei-copy.spl` | Owner, recipients and fire count for all three alerts |
| `75.sh` | Commands |

## Commands

These are in `75.sh`. Nothing has been run. Only apply if you really want the copy.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/75-pddw0100-status-fukusei-copy"
terraform init
terraform validate
terraform plan
```
