# Business Service And Assignment Group Workflow

## Decision tree

```
Davis problem ACTIVE (created)
 │
 ├─ extract-event-tags
 │    ├─ group tags found? ──────────── yes → keep all, in this order:
 │    │                                   1. AGO_AXA_SUPPORTGROUP
 │    │                                   2. specific tag like AGO_ORACLE_ASSIGNMENT_GROUP
 │    │                                   3. AGO_DEFAULT_ASSIGNMENT_GROUP
 │    ├─ environment tag? ───────────── real env tag first, patch env tag last
 │    └─ maintenance? ───────────────── event field first, AGO_Maintenance tag second
 │
 ├─ resolve-snow-values (GET only)
 │    ├─ ASSIGNMENT GROUP
 │    │    ├─ GROUP_MAP hit and active in SILVA? → use it
 │    │    ├─ else each tag candidate: active in SILVA? → first real one wins
 │    │    └─ none? → later: service group → CI group → default group
 │    │
 │    └─ BUSINESS SERVICE
 │         ├─ A. SERVICE_MAP or service tag → exact name lookup
 │         ├─ B. host or DB CI found → CI field → svc_ci_assoc → cmdb_rel_ci
 │         ├─ C. searches (group sys_id, DB + env, DB + region, trigram, technical)
 │         │      → score ≥ 5 and clearly best? → use it
 │         └─ none → "not found", check service_candidates, fill SERVICE_MAP
 │
 └─ display-result
      ├─ group sys_id missing? ─────── ready_for_snow false
      ├─ no service and no CI? ─────── ready_for_snow false
      ├─ maintenance on? ───────────── create_incident false
      └─ otherwise ─────────────────── create_incident true (preview only)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does v4 add? | A `snow_required` block with the two values SNOW needs, each with a sys_id and a "from" field |
| How is the group picked? | Every group tag is checked in SILVA. The first active one wins. |
| Which group tag wins now? | `AGO_ORACLE_ASSIGNMENT_GROUP` is tried before `AGO_DEFAULT_ASSIGNMENT_GROUP` |
| How is the business service picked? | Fixed map, then the CI, then scored searches |
| What if the service is not found? | You see the top 10 candidates. Put the right name in `SERVICE_MAP` once. |
| Does it post anything? | No. It only runs GET calls and shows payload previews. |
| Is it safe to push? | No. The password is in the file. Keep it local. |

## Summary

The step-1 result was fine for tags, but it did not prove the group exists and it had no business service. v4 checks the group in SILVA and returns its sys_id. It then searches for the business service in a fixed order and puts both answers at the top of the output. `ready_for_snow` shows at a glance whether SNOW would accept the ticket.

## What was wrong in the step-1 result

| Finding | Why it matters | v4 fix |
|---|---|---|
| The default group tag was used even though a specific Oracle group tag exists | A specific team tag is usually more accurate | Specific tags are tried before the default tag |
| The group name was never checked in SILVA | SNOW rejects or ignores a group name it does not know | Each candidate is looked up in `sys_user_group` with `active=true` |
| The environment came from `AGO_AXAPATCHENVIRONMENT_ORACLE` | A patch environment tag is not always the real environment | Real environment tags are tried first. The patch tag is only a fallback. |
| Maintenance was read only from the tag | The event has its own `maintenance.is_under_maintenance` field | The event field comes first, then the tag |
| No business service tag | Only a search can find the service | Search 1 now uses the group sys_id exactly, instead of a name LIKE |
| Problems API failed with a missing scope | Evidence details (such as error rate) are lost | Add `environment-api:problems:read` in Workflow Settings → Authorization |

## Output blocks

| Block | What it means |
|---|---|
| `snow_required` | The answer: assignment group, business service, offering, CI and environment |
| `ready_for_snow` | True when a real group sys_id exists and SNOW has a service or a CI |
| `missing` | Why the ticket is not ready yet |
| `decision` | Whether OPEN would create an incident, with the reason |
| `dynatrace_alert` | Alert fields taken from the event |
| `servicenow_enrichment` | The correctoutput.sh layout for the chosen service |
| `snow_incident_payload` | The body the OPEN workflow would POST |
| `pagerduty_payload` | The body the OPEN workflow would send to PagerDuty |
| `lookup` | Group checks, search terms, service candidates, CIs and every API step |
| `tags` | All tags, split into AGO tags and other tags |

## Expected result for your Oracle event

| Field | Expected value |
|---|---|
| `assignment_group.name` | Database_AXAJP |
| `assignment_group.sys_id` | 5223d8c61b8f3c54688064e4604bcb12 |
| `assignment_group.from` | tag AGO_ORACLE_ASSIGNMENT_GROUP |
| `environment.label` | Integration / Test (from the patch environment tag; confirm this) |
| `business_service` | Found by CI or search, or "not found" with candidates listed |

## How to fix a wrong business service

| Step | What to do |
|---|---|
| 1 | Run the workflow and open `lookup.service_candidates` |
| 2 | Pick the correct service name. Check it with the SILVA team if unsure. |
| 3 | Add it to `SERVICE_MAP`, for example `ALJ: "exact service name"` |
| 4 | Run again. `business_service.from` should say `SERVICE_MAP`. |

The same works for the group with `GROUP_MAP` if the tag group is wrong.

## Data flow

```
Dynatrace event
   │ entity_tags, display_id, names, maintenance field, security context
   ▼
extract-event-tags
   │ group_candidates [ORACLE tag, DEFAULT tag]
   │ environment {tag_value, label, from}
   │ host deaa310b, DB DEA10B01, db_type ORACLE, trigram ALJ, region AP-SOUTHEAST-1
   ▼
resolve-snow-values  ── GET ──►  SILVA
   │   sys_user_group      → group name + sys_id
   │   cmdb_ci             → host or DB CI
   │   svc_ci_assoc        → service linked to the CI
   │   cmdb_rel_ci         → parent service of the CI
   │   cmdb_ci_service     → scored searches
   │   service_offering    → offering for the environment
   ▼
display-result
   │ snow_required, ready_for_snow, missing, decision
   │ snow_incident_payload (preview)
   │ pagerduty_payload (preview)
   ▼
console log + task result (nothing sent)
```

## Related files

| File | What it is |
|---|---|
| `3-extract-v4-business-service-and-group.workflow.yaml` | The new workflow to upload |
| `3.sh` | curl one-liners to check the same lookups by hand |
| `../1-extract-v3-tag-based-service-search/` | The previous version (v3) |
| `../2-workflow-output-format-summary/` | Output format summary |

## Commands

See `3.sh`. The key checks are:

```bash
curl -s -G -u 'Tech_DynatraceJP_WS:<password>' 'https://silvastg.service-now.com/api/now/v2/table/sys_user_group' --data-urlencode 'sysparm_query=name=Database_AXAJP^active=true' --data-urlencode 'sysparm_fields=sys_id,name,active' | jq
curl -s -G -u 'Tech_DynatraceJP_WS:<password>' 'https://silvastg.service-now.com/api/now/v2/table/cmdb_ci_service' --data-urlencode 'sysparm_query=assignment_group=5223d8c61b8f3c54688064e4604bcb12^ORsupport_group=5223d8c61b8f3c54688064e4604bcb12' --data-urlencode 'sysparm_fields=sys_id,name,number,operational_status' --data-urlencode 'sysparm_display_value=true' | jq
```
