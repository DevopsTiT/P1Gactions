# PDDW0100 Status Test Copy

## Decision tree

```
Claims Status Service PDDW0100 Status_test
 search same as production (seq 73)? → yes, line for line
 schedule same?                      → yes, 08:15 daily, last 24 h, expires 1 h
 recipients?                         → one person only (personal test)
 → test copy → do NOT migrate (production seq 73 already covers it)
 still want a test detector?         → optional tf: own resource name, enabled = false, low, pd 0
 cut-over                            → ask the owner to delete the Splunk _test alert
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a real alert? | No. It is a test copy of PDDW0100 Status. |
| What is different from production? | Only the title and the recipient (one person). |
| Migrate it? | No. Seq 73 already watches the same runs. |
| If you want it anyway | Use the optional tf. It is disabled, low severity, and has its own resource name. |
| PagerDuty | "0" |

## Summary

The `_test` alert runs exactly the same search at the same time as the production PDDW0100 alert. It only mails one person, which is a sign someone made it to try changes. Migrating it would create a second problem for every unfinished PDDW run. The optional file is there only if you want a safe sandbox copy.

## Investigation

| What I compared | Production (seq 73) | _test |
|---|---|---|
| Search | PDDW*, latest snapshot per run, Ended OK, claims_job_list lookup | Same |
| Schedule | `15 8 * * *`, last 24 hours | Same |
| Expires | 1 hour | Same |
| Trigger | Results greater than 0, once, for each result | Same |
| Priority | Highest | Same |
| Message | 担当各位 PDDWの完了時刻のレポートを送信致します。 | Same |
| Recipients | Business team plus a CC list | One person (not copied) |
| Include | Link to Alert, inline table | Inline table only |

Note: 10-05 seq 31 listed this test copy under a different owner. The owner may have changed since then. The SPL file has a query that shows the current owner.

## Result

| Item | Value |
|---|---|
| Recommendation | Do not migrate |
| Optional resource | `pddw0100_claims_status_test` |
| Optional state | `enabled = false`, severity low, pagerduty "0" |
| Conflict with seq 73 | None. It has a different resource name. |
| Splunk clean-up | Ask the owner to delete or disable the `_test` alert at cut-over |

## Data flow map

```
PDDW runs → production PDDW0100 detector (seq 73) → problem per unfinished run → email route
         ↘ _test copy → (not migrated) → optional disabled detector for experiments only
```

## Related files

| File | What it is |
|---|---|
| `74-pddw0100-status-test-copy-optional.tf` | Optional, disabled test detector |
| `74-pddw0100-status-test-copy-check.dql` | Same checks as seq 73 |
| `74-pddw0100-status-test-copy.spl` | Owner, recipients and how often each copy fired |
| `74.sh` | Commands |

## Commands

These are in `74.sh`. Nothing has been run. Only apply if you really want the test copy.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/74-pddw0100-status-test-copy"
terraform init
terraform validate
terraform plan
```
