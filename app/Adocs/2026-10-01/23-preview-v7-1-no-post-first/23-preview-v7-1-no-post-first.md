# PREVIEW v7.1 No Post First

## Decision tree

```
Import PREVIEW v7.1 (no POST)
  Run (no event) → sample P-260916863, or wait for a real problem
  preview-silva-incident
    ready true  → all keys filled with sys_ids, no duplicate
    ready false → read "problems" and "field_check" (MISSING, WRONG, EMPTY)
  preview-pagerduty
    all checks OK → body is ready
  open_v7_would
    "create" → OPEN v7 would post this
    "skip: maintenance is on" → check AGO_Maintenance tag or USE_MAINTENANCE_TAG
    "skip: missing ..." → fix the missing field source
  run SILVA verify (seq 21) on the values → all pass → import OPEN v7
```

## Short takeaway

| Question | Answer |
|---|---|
| Which file? | `23-preview-v7-1-no-post-first.workflow.yaml` |
| Does it send anything? | No. Only GET lookups in SILVA. No POST, no PagerDuty call, no routing key in the file. |
| What changed from v7? | Tag keys written with hyphens now match too, e.g. AGO-DEFAULT-ASSIGNMENT-GROUP. |
| Are SILVA and PagerDuty parallel? | Yes. Both preview tasks start after build-payload. |
| Order to roll out? | PREVIEW v7.1 first, then SILVA verify, then OPEN v7. |

## Summary

PREVIEW v7.1 runs the exact same preparation as OPEN v7 and shows the SILVA incident body and the PagerDuty body, but never sends them. Use it first on real problems until every run shows `ready: true` and the values pass the SILVA checks. The hyphen fix is also applied to OPEN v7 (seq 17) and TEST v7 (seq 4), so all three read tags the same way.

## Tasks

| Task | What it does | Runs after |
|---|---|---|
| 1 extract-event-tags | Reads the event and tags: group, environment, maintenance, host. | Trigger |
| 2 resolve-snow-values | SILVA lookups for group, business service, offering, host CI. | Task 1 |
| 3 build-payload | Builds the SILVA body, the PagerDuty body and the decision. | Task 2 |
| 4a preview-silva-incident | Field-by-field check, duplicate check (GET), what OPEN v7 would do. | Task 3 |
| 4b preview-pagerduty | Checks PagerDuty required fields, routing key hidden. | Task 3 (parallel with 4a) |

## Settings to look at (task 1)

| Setting | Current | What it means |
|---|---|---|
| USE_PROBLEM_API | true | Read entity tags from the problem as well as the event. |
| USE_MAINTENANCE_TAG | true | The tag AGO_Maintenance:True blocks the ticket. Set false if only real maintenance windows should block. |
| PREPROD_LABEL | Pre-Production | SILVA environment label used for pre-production tags. |
| isActive (trigger) | true | Runs on every new problem. It is read-only, so this is safe. |

## Tag key change (v7.1)

| Tag as written in Dynatrace | v7 | v7.1 |
|---|---|---|
| AGO_DEFAULT_ASSIGNMENT_GROUP | Matched | Matched |
| AGO-DEFAULT-ASSIGNMENT-GROUP | Not matched | Matched |
| snow-service | Matched | Matched (raw key is still tried first) |

## How to import

1. Dynatrace → Workflows → Upload, and choose the yaml.
2. If PREVIEW v7 is already imported, disable or delete it so you do not get two previews per problem.
3. Press Run, or wait for a real problem.
4. Open task 4a and read `ready`, `open_v7_would`, `problems` and `field_check`.
5. Open task 4b and check that every row is OK.

## Data flow

```
Davis problem CREATED
  → 1 extract-event-tags → 2 resolve-snow-values (GET SILVA) → 3 build-payload
      ├→ 4a preview-silva-incident (GET duplicate only) → ready / open_v7_would
      └→ 4b preview-pagerduty (no call)                 → checks
  nothing is sent
```

## Related files

| File | Purpose |
|---|---|
| `23-preview-v7-1-no-post-first.workflow.yaml` | The workflow to import. Contains the SILVA password, so never commit it. |
| `17-open-v7-silva-pagerduty/` | OPEN v7, updated with the same tag fix. Import after PREVIEW passes. |
| `4-v7-test-extraction-validate/` | TEST v7, updated with the same tag fix. |
| `21-silva-verify-checklist/` | SILVA checks to run on the PREVIEW values. |
| `23.sh` | Check and copy commands. |

## Commands

See `23.sh`.
