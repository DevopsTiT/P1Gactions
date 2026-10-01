# OPEN v7 SILVA And PagerDuty Workflow

## Decision Tree

```
Davis problem CREATED
 └─ 1 extract-event-tags → 2 resolve-snow-values → 3 build-payload
        ├─ 4a post-silva-incident   ┐ both start after build-payload
        └─ 4b trigger-pagerduty     ┘ and run in parallel
        decision.create_incident?
         ├─ no (maintenance or missing data) → 4a skipped, 4b skipped
         └─ yes
              ├─ sample event                → 4a skipped, 4b skipped
              ├─ DRY_RUN                     → 4a dry_run, 4b dry_run
              ├─ SILVA already open          → 4a exists,  4b triggers (PD dedup_key keeps one PD incident)
              └─ normal                      → 4a POST /incident, 4b PD trigger (dedup_key dt-problem-<id>)
```

## Short Takeaway

| Question | Answer |
|---|---|
| File | `17-open-v7-silva-pagerduty.workflow.yaml` |
| Built from | TEST v7 tasks 1 to 3 (fixed extraction and keys) plus the v6 send tasks |
| SILVA keys | `u_business_service`, `cmdb_ci` (offering), `u_configuration_item` (host) |
| Caller and On behalf of | sys_id 8ddef691fb34cf547b0dfe7b4eefdcbc |
| Safe first run | Set `DRY_RUN = true` in tasks 4 and 5, then run on a real problem |
| Before activating | Allowlist silvastg.service-now.com and events.pagerduty.com; turn off TEST v7 and OPEN v6 triggers |

## Summary

OPEN v7 keeps the TEST v7 logic that was verified step by step and adds the two sending tasks. The payload now uses the SILVA keys confirmed on INC30340215, so the Business service, Service Offering and Configuration item fields will be filled on the new incident.

## Tasks

| Task | What it does | Passes to next |
|---|---|---|
| 1 extract-event-tags | Reads the event, tags, environment, app code, host | dynatrace_alert, tags, snow_inputs |
| 2 resolve-snow-values | GET lookups in SILVA: group, business service (not offering), offering for the environment, host CI, company | snow_required, servicenow_enrichment |
| 3 build-payload | Builds the SNOW body, the PagerDuty body and the decision | snow_incident_payload, pagerduty_payload, decision |
| 4a post-silva-incident | Skips, finds an existing open incident, or POSTs a new one (parallel with 4b) | number, sys_id, url, action |
| 4b trigger-pagerduty | Sends the trigger with the problem id as link to SILVA (parallel with 4a) | status, dedup_key |

## SNOW Payload Keys

| Key | Value source |
|---|---|
| caller_id | 8ddef691fb34cf547b0dfe7b4eefdcbc (Dynatrace JP) |
| u_on_behalf_of | 8ddef691fb34cf547b0dfe7b4eefdcbc (Dynatrace JP) |
| contact_type | event |
| company | servicenow_enrichment company, else DEFAULT_COMPANY |
| u_environment | Environment label from the event |
| u_business_service | Business service sys_id |
| cmdb_ci | Service offering sys_id |
| u_configuration_item | Host CI sys_id |
| category | other |
| subcategory | other |
| impact | 4 |
| urgency | 4 |
| assignment_group | Group by GROUP_ORDER |
| short_description | [DYNATRACE JAPAN][host] - event name |
| description | Event description plus Additional Information |
| correlation_id | Problem display ID (P-...) |

## When Task 4 Skips

| Reason | What it means |
|---|---|
| maintenance is on | Entity is in a maintenance window |
| missing: ... | Group, business service, offering, environment or short description is empty |
| sample event | Manual Run without a real problem |
| exists | An active incident with the same correlation_id is already open |

## Changes Compared With OPEN v6

| Area | v6 | v7 |
|---|---|---|
| Business service key | business_service (ignored by SILVA) | u_business_service |
| Offering key | service_offering (ignored) | cmdb_ci |
| Host CI key | cmdb_ci | u_configuration_item |
| Caller | Name | sys_id |
| Group | Default group often won | servicenow_enrichment group unless a group tag exists |
| Environment | env:PRE and security context ignored | Read from tags and security context |
| Business service search | Could pick an offering record | Offerings excluded |
| PD custom_details | business service only | Adds service offering |

## Data Flow

```
Davis problem
  → extract-event-tags
  → resolve-snow-values  (GET SILVA)
  → build-payload        (decision, SNOW body, PD body)
  ├→ post-silva-incident (GET duplicate check → POST /api/now/v2/table/incident)
  └→ trigger-pagerduty   (POST events.pagerduty.com/v2/enqueue)        ← parallel
CLOSE workflow later resolves with the same correlation_id and dedup_key
```

## Commands

Check the incident the workflow created (also in [`17.sh`](17.sh)):

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=correlation_id=P-<problem id>" --data-urlencode "sysparm_fields=number,u_business_service,cmdb_ci,u_configuration_item,assignment_group,u_environment,caller_id" --data-urlencode "sysparm_display_value=true" | jq '.result'
```

## Related Files

| File | What it is |
|---|---|
| `17-open-v7-silva-pagerduty.workflow.yaml` | The new OPEN workflow |
| `../4-v7-test-extraction-validate/` | TEST v7 (read-only, same logic) |
| `../16-final-keys-confirmed-inc30340215/` | Key confirmation |
| `17.sh` | Check and copy commands |
