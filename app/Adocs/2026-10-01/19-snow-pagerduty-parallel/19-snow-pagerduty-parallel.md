# SILVA And PagerDuty In Parallel

## Decision Tree

```
build-payload (decision, SNOW body, PD body)
 ├─ post-silva-incident   ┐  both predecessors = build-payload
 └─ trigger-pagerduty     ┘  start at the same time, neither waits for the other
       each task checks on its own:
         decision.create_incident false → skip
         sample event                   → skip (unless ALLOW_SAMPLE_POST)
         DRY_RUN                        → dry_run
       SILVA only: open incident with same correlation_id → exists (no POST)
       PD only:    same dedup_key while alert is open      → PD keeps one incident
```

## Short Takeaway

| Question | Answer |
|---|---|
| What changed | `trigger-pagerduty` now depends on `build-payload`, not on `post-silva-incident` |
| Files changed | OPEN v7 (`17-...workflow.yaml`) and PREVIEW v7 (`18-...workflow.yaml`) |
| Gain | PagerDuty pages immediately, even if SILVA is slow or down |
| Trade-off | The PD alert no longer contains the SILVA INC number; it carries the problem id (correlation_id) instead |
| Duplicate safety | SILVA: correlation_id check. PagerDuty: dedup_key `dt-problem-<id>` |

## Summary

Both send tasks now start right after `build-payload` and run side by side. Each task makes its own skip decision from the same `decision` object, so they always agree. Because PagerDuty no longer waits, it cannot show the INC number; on-call finds the SILVA ticket by the problem id, which is the incident's correlation_id.

## Before And After

| Item | Before (serial) | After (parallel) |
|---|---|---|
| trigger-pagerduty predecessor | post-silva-incident | build-payload |
| Graph position | x 0, y 5 | x 1, y 4 (beside SILVA) |
| SILVA failure | PD never runs (no page) | PD still pages |
| PD custom_details | snow_incident number and URL | snow_correlation_id (problem id) |
| PD links | SILVA incident URL | Dynatrace problem URL |
| SILVA already open | PD skipped | PD sends; same dedup_key keeps one PD incident |
| Sample event | PD skipped via SILVA result | PD checks `used_sample_event` itself |

## Why PD Does Not Check SILVA For Duplicates

| Option | Problem |
|---|---|
| PD runs a GET for open incidents | It can race with the parallel POST and see the brand-new ticket, then wrongly skip |
| Rely on PD dedup_key | Same key while open = same PD incident. Safe and simple. Chosen. |

## PREVIEW v7

| Task | Now |
|---|---|
| preview-silva-incident | After build-payload (unchanged) |
| preview-pagerduty | After build-payload, parallel; `open_v7_would` computed from decision and sample flag |

## Data Flow

```
extract → resolve (GET SILVA) → build-payload
                                  ├→ post-silva-incident → SILVA INC (correlation_id = P-...)
                                  └→ trigger-pagerduty   → PD alert  (dedup_key = dt-problem-P-...)
CLOSE: resolves SILVA by correlation_id and PD by dedup_key (independent, also parallel-safe)
```

## Related Files

| File | What it is |
|---|---|
| `../17-open-v7-silva-pagerduty/17-open-v7-silva-pagerduty.workflow.yaml` | OPEN v7, parallel |
| `../18-preview-v7-no-post/18-preview-v7-no-post.workflow.yaml` | PREVIEW v7, parallel |
| `19.sh` | Copy commands |
