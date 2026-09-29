# Extract Tags And SILVA Enrichment Workflow

## Decision tree

```
Problem ACTIVE (CREATED)  — or press Run to use SAMPLE_EVENT
 │
 ├─ Task 1 extract-event-tags
 │    entity_tags + problem entity tags → parse "[Context]KEY:value"
 │    → tags.ago / tags.other / tags.raw
 │    → hints: assignment group, business service, environment, trigram, platform, region, maintenance, host
 │    → dynatrace_alert: service_name, alerting_profile, severity, event_name, error_rate
 │
 ├─ Task 2 lookup-silva  (HTTP GET only)
 │    business service tag or SERVICE_MAP[trigram]? → cmdb_ci_service by name
 │    else host / entity name → cmdb_ci → svc_ci_assoc → cmdb_ci_service
 │    assignment group tag → sys_user_group (exists? sys_id?)
 │    nothing found → servicenow_enrichment.found = false (+ steps show why)
 │
 └─ Task 3 display-result
      combine → task result + console log (same shape as correctoutput.sh)
```

## Short takeaway

| Question | Answer |
|---|---|
| Does it create a SILVA incident? | No. It only reads SILVA with GET calls. |
| Does it call PagerDuty? | No. |
| Where do the tags come from? | The trigger event's `entity_tags`, plus the Problems API entity tags when that call is allowed |
| Where does the enrichment come from? | The SILVA business service record (`cmdb_ci_service`), found by tag, by `SERVICE_MAP`, or by host → CI → `svc_ci_assoc` |
| Where do I see the result? | In the workflow execution, open task `display-result`. The Result tab shows the JSON and the Log tab shows the same JSON printed. |
| Can I test without a real problem? | Yes. Press Run. With no trigger event, the built-in `SAMPLE_EVENT` (your Oracle event) is used. |

## Summary

The workflow has three tasks. The first reads every tag and the main alert fields from the Dynatrace event. The second looks up the matching business service and group in SILVA, read-only. The third combines both into one JSON like your `correctoutput.sh` and prints it. The file is `1-extract-tags-silva-enrichment.workflow.yaml`.

## Task 1: extract-event-tags

**Tag parsing:**

| Tag in the event | key | value | context |
|---|---|---|---|
| `AGO_DEFAULT_ASSIGNMENT_GROUP:Database_AXAJP` | AGO_DEFAULT_ASSIGNMENT_GROUP | Database_AXAJP | (none) |
| `[Environment]AGO_AXA_SUPPORTGROUP:X` | AGO_AXA_SUPPORTGROUP | X | Environment |
| `host:deaa310b` | host | deaa310b | (none) |
| `AGO_DB:ORACLE` | AGO_DB | ORACLE | (none) |

Tags whose key starts with `AGO_` go into `tags.ago`, and the rest go into `tags.other`. If a key appears more than once, its values become a list.

**Hints (used by task 2), found by key name:**

| Hint | Keys checked, first match wins | Sample event result |
|---|---|---|
| assignment_group | `AGO_AXA_SUPPORTGROUP`, then `AGO_DEFAULT_ASSIGNMENT_GROUP`, then any key ending in `ASSIGNMENT_GROUP` or `SUPPORTGROUP` | Database_AXAJP |
| business_service | `snow-service`, `AGO_AXA_BUSINESSSERVICE`, `business-service`, `u_business_service` | (none) |
| environment | `AGO_AXAENVIRONMENTNAME`, then any key containing `ENVIRONMENT`, then `env` | ACCEPTANCE (from `AGO_AXAPATCHENVIRONMENT_ORACLE`) |
| trigram | Any key containing `TRIGRAM` | ALJ |
| platform | Any key containing `PLATFORM` | AWS_IAAS |
| region | Any key containing `REGION` | AP-SOUTHEAST-1 |
| maintenance | Any key containing `MAINTENANCE` | True |
| host | `host` | deaa310b |

**dynatrace_alert fields:**

| Field | Source, first value wins |
|---|---|
| service_name | Root cause name, affected entity names, the entity-type field in the event, problem affected entities, host tag, affected entity id |
| alerting_profile | `labels.alerting_profile` |
| severity | `event.severity`, then `event.category`, then the problem severity |
| event_name | `event.name`, then the problem title |
| error_rate | An evidence property or event field whose name contains "failure rate" or "error rate". A plain number gets two decimals and a `%` sign. |
| problem_id | `display_id` |
| impact_level | `dt.davis.impact_level` |
| affected_entity_ids / types / names | The event lists (plus the problem's affected entities) |

## Task 2: lookup-silva (read only)

| Order | How | SILVA calls |
|---|---|---|
| 1 | A business service tag, or `SERVICE_MAP[trigram]` (for example `ALJ`) | GET `cmdb_ci_service?name=...` |
| 2 | The host tag or affected entity names, looked up as a CI | GET `cmdb_ci`, then GET `svc_ci_assoc`, then GET `cmdb_ci_service` by sys_id |
| 3 | Assignment group tag | GET `sys_user_group?name=...` (only checks that it exists and gets its sys_id) |

`sysparm_display_value=all` returns both the name and the sys_id of each reference field. That is how `assignment_group` and `assignment_group_id` both appear, as in your picture.

**servicenow_enrichment fields (same as picture 1):**

| Field | SILVA field |
|---|---|
| sys_id | sys_id |
| business_service | name |
| number | number (for example BSN0015271) |
| category | category |
| service_classification | service_classification |
| assignment_group / assignment_group_id | assignment_group (name and sys_id) |
| support_group / support_group_id | support_group (name and sys_id) |
| company / company_id | company (name and sys_id) |
| managed_by | managed_by (sys_id) |
| u_bbsa_id | u_bbsa_id |
| u_business_range | u_business_range |
| business_criticality | business_criticality |
| u_cmdb_properties | u_cmdb_properties |
| comments | comments |

## Task 3: display-result

It combines both results. Example for the sample Oracle event, where the SILVA part depends on what SILVA returns:

```json
{
  "dynatrace_alert": {
    "service_name": "CUSTOM_DEVICE-C782F52B95F89F6F",
    "alerting_profile": "Default",
    "severity": "3",
    "event_name": "Oracle DB instance down",
    "error_rate": "",
    "problem_id": "P-SAMPLE",
    "impact_level": "Infrastructure"
  },
  "servicenow_enrichment": {
    "sys_id": "<from SILVA>",
    "business_service": "<from SILVA>",
    "number": "BSN...",
    "assignment_group": "<from SILVA>",
    "assignment_group_id": "<sys_id>",
    "support_group": "<from SILVA>",
    "company": "<from SILVA>"
  },
  "routing": {
    "assignment_group_from_tag": { "from_tag": "AGO_DEFAULT_ASSIGNMENT_GROUP", "name": "Database_AXAJP", "exists_in_silva": true },
    "environment_tag": { "key": "AGO_AXAPATCHENVIRONMENT_ORACLE", "value": "ACCEPTANCE" },
    "trigram_tag": { "key": "AGO_AXAOPCOTRIGRAM_ORACLE", "value": "ALJ" },
    "maintenance_tag": { "key": "AGO_Maintenance", "value": "True" }
  },
  "tags": {
    "count": 13,
    "ago": { "AGO_AXAOPCOTRIGRAM_ORACLE": "ALJ", "AGO_DEFAULT_ASSIGNMENT_GROUP": "Database_AXAJP", "...": "..." },
    "other": { "Test_Maintenance": "True", "host": "deaa310b" }
  },
  "lookup": { "found": true, "method": "CI deaa310b -> svc_ci_assoc", "steps": [ "..." ] }
}
```

If SILVA has no CI named `deaa310b` and there is no business service tag, `servicenow_enrichment` shows `found: false`, and `lookup.steps` shows each call with its status and match count. The fix is then to add the trigram to `SERVICE_MAP`, for example `ALJ: "AFA EIP (Socle)@0000"` if that is the right service.

## How to import and run

1. In Dynatrace, open Workflows, then Upload (import) and choose `1-extract-tags-silva-enrichment.workflow.yaml`.
2. Add `silvastg.service-now.com` to the External requests allowlist (Settings → General → External requests), if it is not already there.
3. Press **Run** once. It uses `SAMPLE_EVENT`.
4. Open task `display-result`, then Result, to see the JSON.
5. If `lookup-silva` shows status 401 or 403 in `steps`, check the password or the SILVA read access.
6. When the result looks right, leave the trigger on. Each new problem then produces this output, without touching SILVA or PagerDuty.

## Settings you can change

| Setting | Task | What it does |
|---|---|---|
| `SAMPLE_EVENT` | 1 | The test event used when you press Run |
| `USE_PROBLEM_API` | 1 | Reads extra tags and the error rate from the Problems API |
| `ENABLED` | 2 | `false` skips SILVA completely (tags only) |
| `SERVICE_MAP` | 2 | Trigram or system tag value mapped to the exact business service name |
| `SERVICE_FIELDS` | 2 | Which business service fields are read |

## Data flow map

```
Davis problem event (or SAMPLE_EVENT on Run)
        │
 extract-event-tags ── entity_tags ──► parse KEY:value ──► tags.ago / tags.other / hints
        │            └ getProblem (optional) ──► extra tags, error rate, title
        ▼
 lookup-silva (GET only)
   hint business_service / SERVICE_MAP[trigram] ──► cmdb_ci_service
   host / entity name ──► cmdb_ci ──► svc_ci_assoc ──► cmdb_ci_service
   hint assignment_group ──► sys_user_group
        ▼
 display-result ──► { dynatrace_alert, servicenow_enrichment, routing, tags, lookup }
                    task Result tab + Log tab
```

## Related files

| File | Purpose |
|---|---|
| `1-extract-tags-silva-enrichment.workflow.yaml` | The new workflow |
| `1.sh` | curl calls that match what task 2 does, for testing outside Dynatrace |
| `../../2026-09-28/33-explain-open-close-workflow-dataflow/` | How the full OPEN and CLOSE workflows work |

## Commands

See `1.sh` (not run). Same lookups as task 2, for the sample host:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci?sysparm_query=name=deaa310b%5EORfqdn=deaa310b&sysparm_fields=sys_id,name,sys_class_name,install_status,support_group&sysparm_display_value=true" | jq '.result'
```
