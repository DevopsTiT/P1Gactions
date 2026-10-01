# Preview Then Post v7.1

## Decision tree

```
Problem trigger
  extract-event-tags → resolve-snow-values → build-payload
        ├→ preview-silva-incident ──→ post-silva-incident
        │     decision skip?                 → skipped (reason)
        │     preview problems (MISSING/WRONG)? → skipped
        │     sample event?                  → skipped
        │     open incident exists?          → exists
        │     DRY_RUN?                       → dry_run
        │     else POST /incident            → created + INC
        └→ preview-pagerduty ───────→ trigger-pagerduty
              decision skip?                 → skipped
              preview ready false?           → skipped
              sample event?                  → skipped
              DRY_RUN?                       → dry_run
              else POST /v2/enqueue          → triggered
```

## Short takeaway

| Question | Answer |
|---|---|
| File | `30-preview-then-post-v7-1.workflow.yaml` |
| Layout | Same as your PREVIEW graph, plus one sending task under each preview. |
| Does it send? | Yes. SILVA incident and PagerDuty trigger. |
| Parallel? | Yes. The SILVA branch and the PagerDuty branch run side by side. |
| Extra safety | Each send also skips when its own preview is not ready. |
| Checked | YAML parses, wiring confirmed, all seven scripts pass a syntax check. |

## Summary

This keeps the PREVIEW you already tested and adds the sending step directly below each preview. The SILVA POST waits for the SILVA preview, and the PagerDuty trigger waits for the PagerDuty preview. One run shows the check and the action together.

## Graph

| Task | Position | Runs after | Sends? |
|---|---|---|---|
| extract-event-tags | column 0, row 1 | Trigger | No |
| resolve-snow-values | column 0, row 2 | extract-event-tags | No (SILVA GET) |
| build-payload | column 0, row 3 | resolve-snow-values | No |
| preview-silva-incident | column 0, row 4 | build-payload | No (GET duplicate) |
| preview-pagerduty | column 1, row 4 | build-payload | No |
| post-silva-incident | column 0, row 5 | preview-silva-incident | Yes, SILVA POST |
| trigger-pagerduty | column 1, row 5 | preview-pagerduty | Yes, PagerDuty POST |

## What changed compared with OPEN v7.1

| Item | OPEN v7.1 (seq 29) | Preview then post (seq 30) |
|---|---|---|
| Send tasks start after | build-payload | Their own preview task |
| Preview tasks | None | Kept, same as PREVIEW v7.1 |
| SILVA send also skips when | Decision skip, sample, duplicate | Same, plus preview found MISSING or WRONG fields |
| PagerDuty send also skips when | Decision skip, sample | Same, plus preview checks failed |
| Title | AGO - OPEN Problem to SILVA incident and PagerDuty v7.1 | AGO - PREVIEW then POST to SILVA and PagerDuty v7.1 |

## Settings

| Task | Setting | Current |
|---|---|---|
| extract-event-tags | USE_MAINTENANCE_TAG | true |
| post-silva-incident | DRY_RUN | false |
| post-silva-incident | ALLOW_SAMPLE_POST | false |
| trigger-pagerduty | ROUTING_KEY | 222651db… |
| trigger-pagerduty | DRY_RUN | false |
| trigger-pagerduty | ALLOW_SAMPLE_POST | false |
| Workflow | hourlyExecutionLimit | 1000 |

## How to import

| Step | Action |
|---|---|
| 1 | Allowlist silvastg.service-now.com and events.pagerduty.com. |
| 2 | Disable the PREVIEW-only, TEST and OPEN workflows so one problem is handled once. |
| 3 | Upload the yaml. The graph looks like your PREVIEW, with two new boxes at the bottom. |
| 4 | Optional first run: set DRY_RUN true in both send tasks. |
| 5 | On a real problem, read the preview first, then the send task under it. |

## Data flow

```
problem → tags → SILVA GET → payload + decision
   ├→ preview SILVA (check, dup GET) → post SILVA (POST /incident) → INC
   └→ preview PD (check)             → trigger PD (POST /v2/enqueue) → PD incident
```

## Related files

| File | Purpose |
|---|---|
| `30-preview-then-post-v7-1.workflow.yaml` | The workflow. Contains the password and routing key, never commit. |
| `23-preview-v7-1-no-post-first/` | Preview-only version. |
| `29-open-v7-1-post-both-ends/` | Send-only version without previews. |
| `30.sh` | Validation and copy commands. |

## Commands

See `30.sh`.
