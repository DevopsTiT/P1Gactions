# Standard Flow Preview Then Post

## Decision tree

```
New Dynatrace to SILVA / PagerDuty workflow change?
 Start from 36-standard-flow-preview-then-post.workflow.yaml
 Keep the 7-task layout below (do not add or reorder tasks without a reason)
 Change goes into a NEW numbered folder (old folders untouched)

Workflow shows "Draft" / "Drafts are not triggered"?
 → Save / Deploy the workflow → trigger becomes active

Post task skipped?
 preview problems not empty   → fix the field listed in problems
 preview-pagerduty not ready  → fix the check that is not OK
 DRY_RUN true                 → set false
 open incident already exists → expected, no duplicate
```

## Short takeaway

| Question | Answer |
|---|---|
| What is the standard flow? | Trigger → extract-event-tags → resolve-snow-values → build-payload → two branches: preview then send. |
| Left branch | preview-silva-incident → post-silva-incident |
| Right branch | preview-pagerduty → trigger-pagerduty |
| Safety gate | Each send task runs only if its own preview passed. |
| Standard file | `36-standard-flow-preview-then-post.workflow.yaml` |

## Summary

This layout, shown in your screenshot of "SILVA and PagerDuty v7.1", is now the standard. Every future change starts from this file and is saved into a new folder. The screenshot shows the workflow is still a Draft, and drafts are not triggered, so it must be saved and deployed before real problems start it.

## The standard tasks

| # | Task | Position | Runs after | What it does |
|---|---|---|---|---|
| 0 | Problem trigger | top | — | Starts on an active problem with severity availability, custom, error, resource or slowdown. |
| 1 | extract-event-tags | (0,1) | trigger | Parses tags and alert fields. Builds the SNOW inputs: group tags, environment, app code, host. |
| 2 | resolve-snow-values | (0,2) | extract-event-tags | Read-only SILVA lookups for business service, offering and the final assignment group. |
| 3 | build-payload | (0,3) | resolve-snow-values | Builds the SILVA incident body, the PagerDuty body and the decision (create or skip). |
| 4 | preview-silva-incident | (0,4) | build-payload | Shows the SILVA body, a check per field and the duplicate check (GET only). |
| 5 | post-silva-incident | (0,5) | preview-silva-incident | Skips if not allowed or already open. Otherwise POSTs the incident to SILVA. |
| 6 | preview-pagerduty | (1,4) | build-payload | Shows the PagerDuty trigger body with the routing key hidden. |
| 7 | trigger-pagerduty | (1,5) | preview-pagerduty | Sends the PagerDuty trigger with dedup_key `dt-problem-<id>` (same key a CLOSE flow uses). |

## Rules for future changes

| Rule | What it means |
|---|---|
| Start from the standard file | Copy this YAML, do not rebuild the graph. |
| New folder per change | Old folders are never edited. |
| Keep the preview gates | A send task must read its preview result and skip if it is not ready. |
| Tasks 1 to 3 stay shared | Both branches use the same build-payload output. |
| Secrets stay local | The YAML holds the SILVA password and PagerDuty routing key. Never commit. |

## Data flow map

```
Problem trigger
   │
   ▼
extract-event-tags ─► resolve-snow-values ─► build-payload
                                                │
                    ┌───────────────────────────┴───────────────────────────┐
                    ▼                                                       ▼
          preview-silva-incident                                   preview-pagerduty
                    │ ready, no problems                                    │ ready
                    ▼                                                       ▼
          post-silva-incident ─► SILVA stg incident               trigger-pagerduty ─► PagerDuty
```

## Related files

| File | Purpose |
|---|---|
| `36-standard-flow-preview-then-post.workflow.yaml` | The standard workflow (copy of seq 34 preview-then-post). |
| `35-preview-p261090-ready-both/` | Proof run: P-261090 preview ready on both branches. |
| `36.sh` | Mirror copy lines. |

## Commands

See `36.sh`. It only has the mirror copy lines and an optional git status check.
