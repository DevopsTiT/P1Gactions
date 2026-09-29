# Investigation

| Source | What was reused or changed |
|---|---|
| Old CLOSE (2026-09-28 seq 27) | Trigger filter, GET by correlation_id, PATCH state 6, PagerDuty resolve in parallel |
| OPEN v6 | Sync keys, sample guard, DRY_RUN pattern |

| Gap in the old CLOSE | v6 fix |
|---|---|
| GET did not filter active incidents | Active first, then any incident to detect "already resolved" |
| Already resolved tickets were patched again | Now reported as already_resolved, no PATCH |
| Manual Run used an empty event | SAMPLE_EVENT with a send guard |
| Notes used old SYSTEM_MAP and placeholder URLs | Notes built from the event (entity, host, group, times, link) |
| Custom problems were not in the trigger | `custom: true` added |
| No dry run | DRY_RUN in tasks 2 and 3 |
