# SNOW And PagerDuty Payload Keys

## Decision Tree

```
Which payload?
 ├─ SILVA incident CREATE (OPEN task 4)  → POST /api/now/v2/table/incident        → 16 keys
 ├─ SILVA incident RESOLVE (CLOSE task 2) → PATCH /api/now/v2/table/incident/<id> → 5 keys
 ├─ PagerDuty TRIGGER (OPEN task 5)       → POST events.pagerduty.com/v2/enqueue  → routing_key, event_action, dedup_key, payload{...}, links
 └─ PagerDuty RESOLVE (CLOSE task 3)      → POST same URL                         → routing_key, event_action, dedup_key
Link between them: correlation_id = display_id ; dedup_key = dt-problem-<display_id>
```

## Short Takeaway

| Question | Answer |
|---|---|
| SNOW create keys | caller_id, u_on_behalf_of, contact_type, company, u_environment, business_service, service_offering, cmdb_ci, category, subcategory, impact, urgency, assignment_group, short_description, description, correlation_id |
| SNOW resolve keys | state, close_code, close_notes, comments, work_notes |
| PagerDuty trigger keys | routing_key, event_action, dedup_key, client, client_url, payload (summary, source, severity, group, component, custom_details), links |
| PagerDuty resolve keys | routing_key, event_action, dedup_key |
| Reference fields | caller_id, u_on_behalf_of, company, business_service, service_offering, cmdb_ci, assignment_group need a sys_id |
| PagerDuty required | routing_key, event_action, dedup_key (for resolve), payload.summary, payload.source, payload.severity |

## Summary

The SNOW create body has 16 keys copied from the INC30340215 form. The resolve body has 5. PagerDuty's trigger uses the Events API v2 shape with a `payload` object; resolve only needs the routing key, the action and the same `dedup_key`. Example bodies are in `6-snow-pagerduty-payload-keys-examples.json`.

## 1. SNOW Create — POST /api/now/v2/table/incident

| Key | Form label | Type | Value comes from | Example (P-260916863, v7) |
|---|---|---|---|---|
| `caller_id` | Caller | Reference to sys_user | Setting CALLER / CALLER_SYS_ID | sys_id of Dynatrace JP |
| `u_on_behalf_of` | On Behalf Of | Reference to sys_user | Setting ON_BEHALF_OF | sys_id of Dynatrace JP |
| `contact_type` | Contact type | Choice | Setting CONTACT_TYPE | `event` |
| `company` | Company | Reference to core_company | servicenow_enrichment.company_id | `b949afc1...` (AXA GROUP OPERATIONS) |
| `u_environment` | Environment | Choice | Environment from tag or security context | `Pre-Production` (confirm label) |
| `business_service` | Business service | Reference to cmdb_ci_service | servicenow_enrichment.sys_id | `189700a6...` (QA Platforms) |
| `service_offering` | Service Offering | Reference to service_offering | Offering for the environment | offering sys_id |
| `cmdb_ci` | Configuration Item | Reference to cmdb_ci | Host or DB CI, only if found | omitted when empty |
| `category` | Category | Choice | Setting CATEGORY | `other` |
| `subcategory` | Subcategory | Choice | Setting SUBCATEGORY | `other` |
| `impact` | Impact | Choice | Setting IMPACT | `4` (4 - Low) |
| `urgency` | Urgency | Choice | Setting URGENCY | `4` (4 - Low) |
| `assignment_group` | Assignment group | Reference to sys_user_group | Group tag, else servicenow_enrichment.assignment_group_id | `6a511cc6...` (AGS_FR_QAS_Service-Managers) |
| `short_description` | Short description | Text, 160 max | `[DYNATRACE JAPAN][target] - event name` | `[DYNATRACE JAPAN][agpo-cloud-web-proxy-*-8080] - Failure rate increase` |
| `description` | Summary | Text | Event description + Additional Information lines | problem id, link, tags |
| `correlation_id` | (hidden) | Text | Problem `display_id` | `P-260916863` |

Optional in v6 only: `assigned_to` (used with the default set when `DEFAULT_SET_ASSIGNED_TO` is filled).

Before POST, OPEN task 4 runs a duplicate check: `GET incident?sysparm_query=correlation_id=<display_id>^active=true`.

## 2. SNOW Resolve — PATCH /api/now/v2/table/incident/{sys_id}

| Key | What it means | Value |
|---|---|---|
| `state` | Incident state | `6` (Resolved) |
| `close_code` | Resolution code | `Solved (Permanently)` (confirm with INC30340215) |
| `close_notes` | Resolution notes, visible to the caller | Short text: problem closed after N min |
| `comments` | Additional comments, visible | Resolve comment setting |
| `work_notes` | Internal notes | Host, entity, group tag, duration, problem link |
| `EXTRA_RESOLVE_FIELDS` | Anything extra your SILVA needs | Empty by default |

The incident is found first with `GET incident?sysparm_query=correlation_id=<display_id>^active=true`.

## 3. PagerDuty Trigger — POST https://events.pagerduty.com/v2/enqueue

| Key | Required? | What it means | Value |
|---|---|---|---|
| `routing_key` | Yes | Integration key of the PagerDuty service | ROUTING_KEY setting |
| `event_action` | Yes | What to do | `trigger` |
| `dedup_key` | Recommended | Groups trigger and resolve into one PD incident | `dt-problem-P-260916863` |
| `client` | No | Tool name shown in PD | `Dynatrace` |
| `client_url` | No | Link back to the problem | Problem URL |
| `payload.summary` | Yes | PD incident title | Same as SNOW short_description |
| `payload.source` | Yes | Affected system | Host, else service name |
| `payload.severity` | Yes | `critical`, `error`, `warning` or `info` | `error` for Infrastructure impact, else `warning` |
| `payload.group` | No | Logical grouping | Environment label |
| `payload.component` | No | Component | Trigram or service name |
| `payload.custom_details` | No | Free key-value details | See next table |
| `links` | No | Clickable links in PD | SILVA incident link, added by task 5 |

**`payload.custom_details` keys:**

| Key | Value |
|---|---|
| `problem_id` | Problem display ID |
| `event_name` | Event name |
| `service_name` | Dynatrace service or entity name |
| `host` | Host |
| `environment` | Environment label |
| `business_service` | Business service name |
| `assignment_group` | Assignment group name |
| `db_type` | DB type tag |
| `trigram` | Trigram or OpCo |
| `snow_correlation_id` | Same as SNOW correlation_id |
| `snow_incident` | SILVA incident number (added by task 5) |
| `snow_incident_url` | SILVA incident link (added by task 5) |

## 4. PagerDuty Resolve — POST https://events.pagerduty.com/v2/enqueue

| Key | Required? | Value |
|---|---|---|
| `routing_key` | Yes | Same routing key as trigger |
| `event_action` | Yes | `resolve` |
| `dedup_key` | Yes | Must equal the trigger's `dt-problem-<display_id>` |

## Common Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Name in a reference field (`caller_id: "Dynatrace JP"`) | Field stays empty | Send the sys_id, or add `sysparm_input_display_value=true` |
| Label instead of value for choices (`impact: "4 - Low"`) | Rejected or blank | Send the stored value (`4`) |
| Different `dedup_key` on resolve | PD incident never closes | Build both from `display_id` |
| `severity` outside the four allowed words | PagerDuty 400 | Use critical, error, warning or info |

## Data Flow

```
Davis problem (display_id P-260916863)
  OPEN  → SILVA POST incident {16 keys, correlation_id=P-260916863}
        → PD trigger {routing_key, trigger, dedup_key=dt-problem-P-260916863, payload, links}
  CLOSE → SILVA GET by correlation_id → PATCH {state 6, close_code, close_notes, comments, work_notes}
        → PD resolve {routing_key, resolve, dedup_key=dt-problem-P-260916863}
```

## Related Files

| File | What it is |
|---|---|
| `6-snow-pagerduty-payload-keys-examples.json` | Example body for all four calls |
| `../4-v7-test-extraction-validate/` | Test workflow that builds and validates the SNOW body |
| `../../2026-09-30/9-v6-full-open-silva-pagerduty/` | OPEN v6 (POST + PD trigger) |
| `../../2026-09-30/11-v6-close-silva-pagerduty/` | CLOSE v6 (PATCH + PD resolve) |
| `6.sh` | Grep one-liners to list the keys in the workflow files, and mirror copies |
