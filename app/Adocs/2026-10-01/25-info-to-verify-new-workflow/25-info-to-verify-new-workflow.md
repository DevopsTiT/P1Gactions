# Info To Verify New Workflow

## Decision tree

```
Did PREVIEW v7.1 run?
  no run at all        → trigger isActive? event filter? hourly limit? workflow enabled?
  task red (failed)    → send that task's error text
  all green
    Task 1 ok?  problemApi "ok", tags.raw has the tags you see in Dynatrace, environment and group candidates right
    Task 2 ok?  every steps[] row HTTP 200, group_checks exists:true, service ≠ offering, offering parent = service
    Task 3 ok?  decision reason makes sense, missing [] when data exists
    Task 4a ok? ready true (or explained), field_check all OK, duplicate_check http 200
    Task 4b ok? ready true, 5 checks OK, starts at same time as 4a
    SILVA ok?   21.sh lines 1 to 9 confirm every sys_id
  all ok on 6 scenarios → import OPEN v7
```

## Short takeaway

| Question | Answer |
|---|---|
| What do I need from you? | For each run: the problem ID, the problem's tags, and the result JSON of all five tasks. |
| How many runs? | Six scenarios cover the logic (listed below). At least three real problems. |
| What proves "working"? | Each task matches the pass rules below, and the SILVA queries confirm the sys_ids. |
| What does not need to be sent? | The password, the routing key, or the whole event_properties list. |

## Summary

To prove the workflow is right, I need to see what went in (the problem and its tags), what each task decided, and whether SILVA agrees. Collect the items below for each scenario, and the pass rules tell you on the spot whether each task is correct.

## Part 1 — what to collect for every run

| # | Where | What to copy | Why it is needed |
|---|---|---|---|
| 1 | Dynatrace problem page | Problem ID (P-…) and title | Identifies the run. |
| 2 | Dynatrace problem page | The entity tags exactly as shown | Proves task 1 read the right input. |
| 3 | Workflow execution graph | Screenshot of all five tasks with status and start times | Proves all tasks ran and 4a and 4b are parallel. |
| 4 | Task 1 result | `usedSample`, `problemApi`, `snow_inputs` (group_candidates, environment, maintenance, app_code, host) | Proves tag parsing. |
| 5 | Task 2 result | `snow_required`, `group_checks`, `offering_candidates`, `cis_found`, `steps` | Proves the SILVA lookups. |
| 6 | Task 3 result | `decision`, `missing`, `snow_incident_payload`, `field_sources` | Proves the body and the decision. |
| 7 | Task 4a result | `ready`, `open_v7_would`, `problems`, `field_check`, `duplicate_check` | Proves SILVA readiness. |
| 8 | Task 4b result | `ready`, `open_v7_would`, `checks` | Proves PagerDuty readiness. |
| 9 | Terminal | Output of `21.sh` lines 1 to 9 with this run's sys_ids | SILVA confirms the values. |

## Part 2 — pass rules per task

### Task 1 extract-event-tags

| Check | Pass |
|---|---|
| problemApi | "ok" for a real problem. "skipped (sample event)" for Run. |
| tags.raw | Contains every tag you see on the problem page. |
| group_candidates | Same group tags as the page, in order: support group, specific, default. |
| environment.label | Matches the tag, e.g. ACCEPTANCE gives Integration / Test. |
| environment.from | Names the tag it came from, not "default", when an env tag exists. |
| maintenance | true only when a maintenance window is active, or AGO_Maintenance:True with USE_MAINTENANCE_TAG true. |
| host | The host of the problem, e.g. deaa310b.prprivmgmt.intraxa. |

### Task 2 resolve-snow-values

| Check | Pass |
|---|---|
| steps[].status | Every row 200. A 401 means login failed. 0 means the host is not allowlisted. |
| group_checks | The chosen group has exists: true. |
| assignment_group.from | "tag …" when a group tag exists. |
| business_service.sys_id | 32 characters, and not the same as service_offering.sys_id. |
| business_service.from | A real method (tag, CI, search). "default" only when nothing matched. |
| service_offering.parent_id | Equals business_service.sys_id. |
| service_offering.from | Ideally "offering of the business service for <environment>". "environment NOT matched" is a warning to confirm. |
| cmdb_ci.sys_id | The host CI is found (32 characters). |

### Task 3 build-payload

| Check | Pass |
|---|---|
| snow_incident_payload | Has all 16 keys when data exists. |
| Reference keys | caller_id, u_on_behalf_of, company, u_business_service, cmdb_ci, u_configuration_item and assignment_group are all sys_ids. |
| correlation_id | Equals the problem ID. |
| short_description | Starts with [DYNATRACE JAPAN] and has the host and event name. |
| decision.reason | "ok", or a reason that matches the facts (maintenance, missing). |

### Task 4a preview-silva-incident

| Check | Pass |
|---|---|
| note | "PREVIEW ONLY - nothing was sent to SILVA". |
| field_check | Every row OK. EMPTY is allowed only for Configuration item. |
| duplicate_check.http | 200. |
| ready | true when the decision is create and nothing is missing. |
| open_v7_would | Matches what you expect for the scenario. |

### Task 4b preview-pagerduty

| Check | Pass |
|---|---|
| checks | All five OK. |
| dedup_key | dt-problem-<problem ID>. |
| routing_key | Shows "__hidden__". |
| Start time | Same as 4a (both start after task 3). |

## Part 3 — scenarios to run

| # | Scenario | How to get it | Expected result |
|---|---|---|---|
| 1 | Manual Run | Press Run with no event | usedSample true. open_v7_would "SKIP (sample event …)". |
| 2 | Real problem with a group tag | An Oracle problem like P-260916434 | Group from tag. ready true unless maintenance. |
| 3 | Maintenance tag | Entity with AGO_Maintenance:True | USE_MAINTENANCE_TAG true gives "SKIP (maintenance is on)". false gives CREATE. |
| 4 | No group tag | A problem on an entity without group tags | Group from service, CI or DEFAULT_GROUP. from field says which. |
| 5 | Hyphen tag key | Entity tag like AGO-DEFAULT-ASSIGNMENT-GROUP | The tag appears in group_candidates (new in v7.1). |
| 6 | Duplicate | A problem that already has an open SILVA incident with that correlation_id | open_v7_would "SKIP (already open: INC…)". |

## Part 4 — SILVA confirmation

Replace the sys_ids in `21.sh` with this run's values from task 3, then run lines 1 to 9. All must pass as described in seq 21 (record exists, active, service is not an offering, offering parent is the service, choices valid, no duplicate).

## Data flow

```
Dynatrace problem (ID + tags) ─→ Task 1 result ─→ Task 2 result ─→ Task 3 result ─┬→ Task 4a result
                                                                                    └→ Task 4b result
Task 3 sys_ids ─→ 21.sh in SILVA ─→ confirmed
all six scenarios pass ─→ import OPEN v7
```

## Related files

| File | Purpose |
|---|---|
| `23-preview-v7-1-no-post-first/` | The workflow being verified. |
| `24-workflow-flow-apis-explained/` | What each task does. |
| `21-silva-verify-checklist/` | SILVA confirmation queries. |
| `25.sh` | Commands for this check. |

## Commands

See `25.sh`.
