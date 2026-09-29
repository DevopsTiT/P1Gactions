# Extract v2 With SNOW And PagerDuty Ready Output

## Decision tree

```
First run result (pics 1–4)
 │
 ├─ tags             → OK (13 tags, hints correct)
 ├─ problem_api      → "OAuth token is missing required scope"
 │                      → Workflow Settings → Authorization → add environment-api:problems:read
 ├─ ci by name deaa310b / DEA10B01 → 0 matches (exact name only)
 │                      → v2: host "starts with deaa310b." and DB "name contains DEA10B01"
 ├─ ci by name CUSTOM_DEVICE-...   → pointless (Dynatrace id)  → v2 skips it
 ├─ group Database_AXAJP           → found (sys_id 5223d8c6...)  → v2 uses it for assignment
 └─ servicenow_enrichment found:false
        v2 order: SERVICE_MAP → service tag → CI → svc_ci_assoc / cmdb_rel_ci
                  → trigram "name contains ALJ" (use if exactly 1) → still none?
                  → lookup.service_candidates lists choices → put one in SERVICE_MAP
```

## Short takeaway

| Question | Answer |
|---|---|
| Why was nothing found? | SILVA was only asked for exact names. The Oracle CI is probably stored as `DEA10B01@deaa310b` or the host as `deaa310b.<domain>`. |
| Why did the Problems API fail? | The workflow does not have the `environment-api:problems:read` permission |
| What does v2 output? | The same two blocks as picture 5 (`dynatrace_alert`, `servicenow_enrichment`), plus `decision`, `snow_incident_payload` and `pagerduty_payload` |
| Does v2 send anything? | No. The two payloads are previews of what OPEN would send. |
| What if SILVA still finds nothing? | `lookup.service_candidates` lists services whose name contains the trigram. Copy the right one into `SERVICE_MAP`. |

## Summary

The first run proved that tag extraction works and that the group `Database_AXAJP` exists in SILVA. The business service was not found because the CI search used exact names only. v2 widens the search (host with domain, DB name contains), follows both CI-to-service link tables, falls back to the trigram, and picks the offering for the environment. The output always has the picture 5 layout, with empty strings when a value is unknown, plus the SNOW and PagerDuty bodies ready to pass on. File: `3-extract-v2-snow-pd-ready-output.workflow.yaml`.

## What the first run tells us

| Output in pics 1–4 | Meaning |
|---|---|
| `tags.count: 13`, `ago` and `other` filled | Tag parsing works |
| `service_name: "DEA10B01"` | Taken from the entity-type field `dt.entity.sql:...oracle_instance` |
| `ci by name deaa310b` with 0 matches | No CI named exactly `deaa310b` |
| `ci by name DEA10B01` with 0 matches | No CI named exactly `DEA10B01` |
| `ci by name CUSTOM_DEVICE-C782...` with 0 matches | Expected. Dynatrace ids are never in SILVA. |
| `group by name Database_AXAJP` with 1 match | Group exists, sys_id `5223d8c61b8f3c54688064e4604bcb12` |
| `problem_api: failed: OAuth token is missing required scope` | Missing workflow permission |
| `servicenow_enrichment.found: false` | Nothing linked the alert to a business service |
| Terminal: `curl: (3) URL rejected: Malformed input to a URL function` | The URL had a space or special character that was not encoded. Use `curl -G --data-urlencode` (see `3.sh`). |

## What v2 changes

| Area | v1 | v2 |
|---|---|---|
| Host CI search | exact name | exact name, then `nameSTARTSWITH deaa310b.` or `fqdnSTARTSWITH deaa310b.` |
| DB or entity CI search | exact name | exact name, then `nameLIKE DEA10B01` |
| Dynatrace ids | sent to SILVA | skipped |
| CI to service | svc_ci_assoc | svc_ci_assoc, then cmdb_rel_ci (any parent whose class contains "service") |
| No CI link | stop | trigram search `nameLIKE ALJ`, active only. Used if exactly 1 match, otherwise listed. |
| Offering | not read | offering under the service whose environment matches |
| Enrichment when not found | `{found:false, reason}` | all picture 5 keys, with empty values plus `found` and `match_method` |
| SNOW and PD | not shown | `snow_incident_payload` and `pagerduty_payload` (not sent) |
| Maintenance | shown only | `decision.create_incident = false` when `AGO_Maintenance` is True (setting `SKIP_WHEN_MAINTENANCE`) |
| Environment | tag value only | tag value plus SILVA label (`ACCEPTANCE` becomes `Integration / Test`, please confirm) |

## Output layout

```json
{
  "dynatrace_alert": {
    "service_name": "DEA10B01",
    "alerting_profile": "Default",
    "severity": "3",
    "event_name": "Oracle DB Instance down",
    "error_rate": "",
    "problem_id": "P-260916434",
    "problem_url": "https://<env>/ui/apps/dynatrace.davis.problems/problem/...",
    "impact_level": "Infrastructure",
    "host": "deaa310b",
    "entity_id": "CUSTOM_DEVICE-C782F52B95F89F6F",
    "entity_type": "dt.entity.sql:com_dynatrace_extension_sql-oracle_instance",
    "environment": "Integration / Test",
    "environment_tag": "ACCEPTANCE",
    "trigram": "ALJ",
    "platform": "AWS_IAAS",
    "region": "AP-SOUTHEAST-1",
    "maintenance": true
  },
  "servicenow_enrichment": {
    "found": true,
    "match_method": "CI DEA10B01@deaa310b -> svc_ci_assoc",
    "sys_id": "...",
    "business_service": "...",
    "number": "BSN...",
    "category": "...",
    "service_classification": "...",
    "assignment_group": "...",
    "assignment_group_id": "...",
    "support_group": "...",
    "support_group_id": "...",
    "company": "...",
    "company_id": "...",
    "managed_by": "...",
    "u_bbsa_id": "...",
    "u_business_range": "...",
    "business_criticality": "...",
    "u_cmdb_properties": "...",
    "comments": "...",
    "service_offering": "...",
    "service_offering_id": "...",
    "configuration_item": "...",
    "configuration_item_id": "...",
    "configuration_item_class": "...",
    "ci_support_group": "...",
    "ci_support_group_id": "..."
  },
  "decision": {
    "create_incident": false,
    "reason": "Maintenance tag is True (SKIP_WHEN_MAINTENANCE)",
    "assignment_group": "Database_AXAJP",
    "assignment_group_id": "5223d8c61b8f3c54688064e4604bcb12",
    "assignment_group_from": "tag AGO_DEFAULT_ASSIGNMENT_GROUP",
    "environment": "Integration / Test",
    "business_service_from": "..."
  },
  "snow_incident_payload": { "short_description": "[DYNATRACE JAPAN][DEA10B01 on deaa310b] - Oracle DB Instance down", "...": "..." },
  "pagerduty_payload": { "event_action": "trigger", "dedup_key": "dt-problem-P-260916434", "...": "..." },
  "tags": { "...": "..." },
  "lookup": { "found": true, "method": "...", "service_candidates": [], "cis_found": [], "steps": [] }
}
```

The values after `found` are placeholders. They come from SILVA.

## How each block is decided

**Assignment group (decision block), first match wins:**

| Order | Source | Your Oracle event |
|---|---|---|
| 1 | Tag group, if it exists in SILVA | Database_AXAJP (exists) |
| 2 | Business service support group | used if the tag group is missing |
| 3 | CI support group | used if both above are missing |
| 4 | Default `Ops_Middleware_Monitoring_AXAJP` | last resort |

**snow_incident_payload (what OPEN would POST):**

| Field | Value |
|---|---|
| short_description | `[DYNATRACE JAPAN][service on host] - event name` |
| description | event name + "Additional Information:" JSON (entity id, host, severity, tags, trigram, platform, region, URL) |
| correlation_id | problem display id (CLOSE uses this) |
| impact / urgency | 4 - Low |
| contact_type | Event |
| u_environment | SILVA label |
| u_host | host |
| assignment_group | group sys_id (or name) |
| business_service / service_offering / cmdb_ci / company | sys_ids when found. Left out when unknown, so SILVA can derive them. |

**pagerduty_payload (what OPEN would send):**

| Field | Value |
|---|---|
| routing_key | `__PD_ROUTING_KEY__` placeholder, so the key is not shown in the result |
| dedup_key | `dt-problem-<display id>` |
| summary | same as short_description |
| source | host |
| severity | error for Infrastructure impact, otherwise warning |
| group | environment |
| component | trigram |
| custom_details | problem id, event, service, host, entity id, environment, business service, group, trigram, platform, region |

## Steps to run v2

1. In the workflow, open Settings, then Authorization, and add `environment-api:problems:read`. This fixes `problem_api`.
2. Import `3-extract-v2-snow-pd-ready-output.workflow.yaml`, or paste the three scripts into your existing workflow.
3. Run it (or wait for the next problem) and open `display-result`.
4. Read `servicenow_enrichment.match_method`:

| match_method | Next step |
|---|---|
| `CI ... -> svc_ci_assoc` or `-> cmdb_rel_ci` | Done. SILVA knows the CI. |
| `trigram ALJ (single match)` | Check that the service is right, then put it in SERVICE_MAP to make it fixed |
| `not found` with `service_candidates` filled | Pick the right one and add `ALJ: "<name>"` to SERVICE_MAP |
| `not found` with no candidates | Run `3.sh` lines 1–4 to find how SILVA names the CI, or ask the SILVA team which business service owns DEA10B01 |

5. When the output is right, OPEN can reuse `snow_incident_payload` and `pagerduty_payload` as they are.

## Data flow map

```
event (or SAMPLE_EVENT)
   │
extract-event-tags ── tags ─► hints (group, trigram, env, host, maintenance)
   │                 └ fields ─► dynatrace_alert (+ env label, entity id, URL)
   ▼
lookup-silva (GET only)
   A SERVICE_MAP / service tag ─► cmdb_ci_service name
   B host exact / host. / DB name contains ─► cmdb_ci
        ─► svc_ci_assoc ─► service       (or cmdb_rel_ci parent service)
   C trigram name contains (1 active match) ─► service   | else candidates
   D service_offering parent=service, env match
   E sys_user_group (tag group)
   ▼
display-result
   dynatrace_alert + servicenow_enrichment (picture 5 layout)
   decision (create?, group, env)
   snow_incident_payload   (preview)
   pagerduty_payload       (preview)
   tags + lookup.steps
```

## Related files

| File | Purpose |
|---|---|
| `3-extract-v2-snow-pd-ready-output.workflow.yaml` | The v2 workflow |
| `3.sh` | curl checks with safe URL encoding (not run) |
| `../1-extract-tags-silva-enrichment/` | v1 workflow |
| `../2-extract-workflow-flow-logic/` | v1 flow logic |

## Commands

See `3.sh`. `curl -G --data-urlencode` encodes spaces, `^` and `@` for you, which avoids the "Malformed input to a URL function" error:

```bash
curl -s -G -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci" --data-urlencode "sysparm_query=nameLIKEDEA10B01^ORnameSTARTSWITHdeaa310b^ORfqdnSTARTSWITHdeaa310b" --data-urlencode "sysparm_fields=sys_id,name,fqdn,sys_class_name,install_status,support_group" --data-urlencode "sysparm_display_value=true" --data-urlencode "sysparm_limit=20" | jq '.result'
```
