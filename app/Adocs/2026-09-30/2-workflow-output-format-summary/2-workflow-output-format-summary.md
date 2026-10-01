# Workflow Output Format — Complete Summary
## dynatrace_alert + servicenow_enrichment + decision + SNOW payload + PagerDuty payload + tags + lookup

## Decision tree

```
Reading one display-result output
 │
 ├─ servicenow_enrichment.found = true ?
 │     yes → check match_method
 │            SERVICE_MAP / tag / CI ...  → trusted, use as is
 │            tag search (score n ...)    → check the name once, then pin it in SERVICE_MAP
 │     no  → lookup.service_candidates → pick one → SERVICE_MAP → run again
 │
 ├─ decision.create_incident = false ?  → reason (maintenance) → no SNOW / PD in OPEN
 │
 ├─ decision.assignment_group_from = default ?  → group tag missing or not in SILVA
 │
 └─ all good → OPEN sends snow_incident_payload and pagerduty_payload as they are
```

## Short takeaway

| Question | Answer |
|---|---|
| What is this output? | The JSON returned by task `display-result` of the extract workflow (v3) |
| Which part matches correctoutput.sh? | `dynatrace_alert` and `servicenow_enrichment` |
| What is added on top? | `decision`, `snow_incident_payload`, `pagerduty_payload`, `tags`, `lookup` |
| Which part goes to SNOW? | `snow_incident_payload` (built from alert, enrichment and decision) |
| Which part goes to PagerDuty? | `pagerduty_payload` |
| Which part is for troubleshooting? | `tags` and `lookup` |

## Summary

The output has seven blocks. The first two describe the alert (from Dynatrace) and the business service (from SILVA), in the same layout as correctoutput.sh. `decision` says whether to open an incident and who gets it. The two payload blocks are the exact bodies OPEN would send to SILVA and PagerDuty. `tags` and `lookup` show the raw inputs and every SILVA search, so you can see why a value was chosen.

---

## 2. End-to-End Data Flow

```
Dynatrace problem event
  │
  ├─── entity_tags, event fields ─────────────────────────────────────►
  │        extract-event-tags
  │            └── dynatrace_alert  +  tags (ago / other / raw)
  │
  ├─── search terms from tags (group, DB type, env, region, trigram, host) ──►
  │        lookup-silva  (GET only)
  │            └── servicenow_enrichment  +  lookup (steps, candidates, CIs)
  │
  └─── display-result
           ├── decision                (create? group? env?)
           ├── snow_incident_payload   ──► OPEN: POST /api/now/v2/table/incident
           └── pagerduty_payload       ──► OPEN: POST events.pagerduty.com/v2/enqueue
      (problem_id links them: SNOW correlation_id and PD dedup_key "dt-problem-<id>")
```

---

## 3. The Seven Blocks

### 3a. Block Overview

| Block | Filled by | Role | Used by |
|---|---|---|---|
| 1 — dynatrace_alert | extract-event-tags | What happened, where, how severe | Everyone (people, SNOW text, PD text) |
| 2 — servicenow_enrichment | lookup-silva | Which SILVA business service owns it | SNOW payload |
| 3 — decision | display-result | Open or skip, group, environment | OPEN logic |
| 4 — snow_incident_payload | display-result | Incident body for SILVA | OPEN SILVA task |
| 5 — pagerduty_payload | display-result | Event body for PagerDuty | OPEN PagerDuty task |
| 6 — tags | extract-event-tags | Every tag, parsed | Troubleshooting |
| 7 — lookup | lookup-silva | How SILVA was searched | Troubleshooting |

### 3b. dynatrace_alert

| Field | What it means | Source | Example (picture 5) | Example (Oracle) |
|---|---|---|---|---|
| service_name | The affected thing | root cause name, affected entity name, entity-type field, host | onelogin.stg.axa.com | DEA10B01 |
| alerting_profile | Dynatrace alerting profile | `labels.alerting_profile` | EIP Test | Default |
| severity | Dynatrace severity number | `event.severity` | 3 | 3 |
| event_name | What happened | `event.name` | Failure rate increase | Oracle DB Instance down |
| error_rate | Failure or error rate, if the event has one | evidence property or event field | 39.06% | (empty) |
| problem_id | Problem number | `display_id` | | P-260916434 |
| problem_url | Link to the problem | built from `event.id` | | https://.../problem/... |
| impact_level | Davis impact level | `dt.davis.impact_level` | | Infrastructure |
| host | Host name | `host` tag or host fields | | deaa310b |
| entity_id | Dynatrace entity id | `affected_entity_ids` | | CUSTOM_DEVICE-C782F52B95F89F6F |
| entity_type | Dynatrace entity type | `affected_entity_types` | | dt.entity.sql:...oracle_instance |
| environment | SILVA environment label | environment tag through the map | | Integration / Test |
| environment_tag | Raw environment tag value | `AGO_AXAPATCHENVIRONMENT_*` or `AGO_AXAENVIRONMENTNAME` | | ACCEPTANCE |
| db_type | Database type | `AGO_DB` | | ORACLE |
| trigram | Application code | `AGO_AXAOPCOTRIGRAM_*` | | ALJ |
| platform | Hosting platform | `AGO_AXAPLATFORM_*` | | AWS_IAAS |
| region | Cloud region | `AGO_CSP_REGION_*` | | AP-SOUTHEAST-1 |
| maintenance | In maintenance | `AGO_Maintenance` | | true |

### 3c. servicenow_enrichment

All keys are always present. They are empty strings when nothing was found.

| Field | What it means | SILVA field | Example (picture 5) |
|---|---|---|---|
| found | A business service was found | (workflow) | true |
| match_method | How it was found | (workflow) | tag search (score 11: ...) |
| sys_id | Business service record id | sys_id | 20b033521b1334506e8e71d4464bcbd8 |
| business_service | Business service name | name | AFA EIP (Socle)@0000 |
| number | Business service number | number | BSN0015271 |
| category | Category | category | Business Service |
| service_classification | Classification | service_classification | Business Service |
| assignment_group | Group that gets tickets | assignment_group (name) | MIM_DSIAF |
| assignment_group_id | Its record id | assignment_group (sys_id) | 787fe236db424f0042b3f7b31d96191b |
| support_group | Group that supports the service | support_group (name) | MIM_DSIAF |
| support_group_id | Its record id | support_group (sys_id) | 787fe236db424f0042b3f7b31d96191b |
| company | Owning company | company (name) | AXA FRANCE ADMIN |
| company_id | Its record id | company (sys_id) | d1ed6952db68f6c8a476f9f51d96194f |
| managed_by | Manager (user record id) | managed_by (sys_id) | 635671d2dba8f6c8a476f9f51d9619b5 |
| u_bbsa_id | AXA business service id | u_bbsa_id | 032683 |
| u_business_range | Business range | u_business_range | 3 |
| business_criticality | Criticality (1 is highest) | business_criticality | 2 |
| u_cmdb_properties | CMDB properties | u_cmdb_properties | AXA Functional Business Service=YES |
| comments | Free-text notes on the service | comments | BS MIM AFA : vu avec ... |
| service_offering | Offering for this environment | service_offering.name | (from SILVA) |
| service_offering_id | Its record id | service_offering.sys_id | (from SILVA) |
| configuration_item | Host or DB record found | cmdb_ci.name | (from SILVA) |
| configuration_item_id | Its record id | cmdb_ci.sys_id | (from SILVA) |
| configuration_item_class | Its record type | cmdb_ci.sys_class_name | (from SILVA) |
| configuration_item_fqdn | Its full domain name | cmdb_ci.fqdn | (from SILVA) |
| ci_support_group | Host or DB support group | cmdb_ci.support_group (name) | (from SILVA) |
| ci_support_group_id | Its record id | cmdb_ci.support_group (sys_id) | (from SILVA) |

### 3d. decision

| Field | What it means | Rule |
|---|---|---|
| create_incident | Whether OPEN should create a ticket | false when `AGO_Maintenance` is True and `SKIP_WHEN_MAINTENANCE` is on |
| reason | Why | "ok", or the maintenance reason |
| assignment_group | Group the ticket goes to | first match: tag group (if it exists in SILVA), service support group, CI support group, default |
| assignment_group_id | Its record id | from SILVA |
| assignment_group_from | Which rule gave the group | for example "tag AGO_DEFAULT_ASSIGNMENT_GROUP" |
| environment | SILVA environment label | from the environment tag through the map |
| business_service_from | Copy of match_method | for a quick check |

### 3e. snow_incident_payload (what OPEN POSTs to SILVA)

| Incident field | Value | Comes from |
|---|---|---|
| short_description | `[DYNATRACE JAPAN][service on host] - event name` | dynatrace_alert |
| description | event name + "Additional Information:" JSON | dynatrace_alert, tags, enrichment |
| correlation_id | problem id | dynatrace_alert.problem_id (CLOSE searches on it) |
| impact | 4 - Low | setting |
| urgency | 4 - Low | setting |
| contact_type | Event | fixed |
| u_environment | environment label | decision.environment |
| u_host | host | dynatrace_alert.host |
| assignment_group | group id (or name) | decision |
| business_service | service id (only if found) | servicenow_enrichment.sys_id |
| service_offering | offering id (only if found) | servicenow_enrichment.service_offering_id |
| cmdb_ci | CI id (only if found) | servicenow_enrichment.configuration_item_id |
| company | company id (only if found) | servicenow_enrichment.company_id |

Unknown values are left out rather than sent empty, so SILVA can still derive them from the CI.

### 3f. pagerduty_payload (what OPEN sends to PagerDuty)

| Field | Value | Comes from |
|---|---|---|
| routing_key | `__PD_ROUTING_KEY__` placeholder | real key stays in OPEN only |
| event_action | trigger | fixed |
| dedup_key | `dt-problem-<problem id>` | dynatrace_alert.problem_id (CLOSE resolves with it) |
| client / client_url | Dynatrace and the problem link | dynatrace_alert |
| payload.summary | same as the SNOW short description | dynatrace_alert |
| payload.source | host | dynatrace_alert.host |
| payload.severity | error for Infrastructure impact, else warning | dynatrace_alert.impact_level |
| payload.group | environment | decision |
| payload.component | trigram | dynatrace_alert.trigram |
| payload.custom_details | problem id, event, service, host, entity id, environment, business service, group, DB type, trigram, platform, region, SNOW correlation id | alert, enrichment, decision |

### 3g. tags

| Field | What it holds |
|---|---|
| count | Number of tags |
| ago | Tags whose key starts with `AGO_`, as key and value |
| other | All other tags, as key and value |
| raw | The original tag strings |

### 3h. lookup

| Field | What it holds |
|---|---|
| found | Same as servicenow_enrichment.found |
| method | Same as match_method |
| search_terms | group, dbType, envTag, regionPrefix and trigram used in the searches |
| service_candidates | Top 10 services with score, found_by and reasons |
| cis_found | Host or DB records found (name, fqdn, sys_id, class) |
| steps | Every SILVA GET with query, status, matches and error |
| used_sample_event | true when started with Run (SAMPLE_EVENT) |
| problem_api | "ok", "skipped", or the error text |

---

## 9. Common Issues and Solutions

### Output issues

| Symptom | Root cause | Solution |
|---|---|---|
| `servicenow_enrichment.found` is false | No search reached the minimum score, or two services tied | Pick from `lookup.service_candidates` and add it to `SERVICE_MAP` |
| A wrong service was picked | Weak tag match won | Raise `MIN_SCORE`, or pin the right one in `SERVICE_MAP` |
| `error_rate` is empty | The event has no rate field (for example DB down) | Normal. It is filled only for failure-rate alerts. |
| `problem_api` shows "missing required scope" | Workflow permission missing | Add `environment-api:problems:read` in the workflow Authorization settings |
| `assignment_group_from` is "default" | No group tag, or the tag group is not in SILVA | Check the group name in `lookup.steps` ("group by name") |
| `configuration_item` is empty | Host or DB not found in SILVA | Check `DOMAINS`, or `lookup.steps` "host by name or fqdn" |
| `create_incident` is false | Maintenance tag is True | Expected. Set `SKIP_WHEN_MAINTENANCE = false` to ignore it. |
| Environment looks wrong | Tag value mapped wrongly (for example ACCEPTANCE) | Fix the `ENVIRONMENT` map |

### SILVA call issues (from lookup.steps)

| Symptom | Root cause | Solution |
|---|---|---|
| status 401 | Wrong password | Fix PASSWORD in lookup-silva |
| status 403 | No read access to that table | Ask the SILVA admin |
| status 0 with an error | Not on the allowlist, or network | Add silvastg.service-now.com to External requests |
| status 200 with matches 0 | Nothing matches that query | Try the same query with 1.sh in seq 1 |

---

## 10. Responsibility Matrix

| Block | Shown to people | Sent to SILVA | Sent to PagerDuty | Used for debugging |
|---|---|---|---|---|
| dynatrace_alert | Yes | Yes, inside short description and description | Yes, inside summary and details | Yes |
| servicenow_enrichment | Yes | Yes, as sys_ids | Business service name only | Yes |
| decision | Yes | Group and environment | Group and environment | Yes |
| snow_incident_payload | Preview | Yes, sent as is by OPEN | No | Yes |
| pagerduty_payload | Preview | No | Yes, sent as is by OPEN | Yes |
| tags | On request | Raw tags inside description | No | Yes |
| lookup | No | No | No | Yes |

## Related files

| File | Purpose |
|---|---|
| `../1-extract-v3-tag-based-service-search/1-extract-v3-tag-based-service-search.workflow.yaml` | The workflow that produces this output |
| `2-workflow-output-format-summary-example.json` | A full example output (Oracle alert, SILVA values as placeholders) |
| `2.sh` | Commands to check the SILVA values behind the output (not run) |

## Commands

See `2.sh`. For example, check the business service from picture 5:

```bash
curl -s -G -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci_service" --data-urlencode "sysparm_query=number=BSN0015271" --data-urlencode "sysparm_fields=sys_id,name,number,category,service_classification,assignment_group,support_group,company,managed_by,u_bbsa_id,u_business_range,business_criticality,u_cmdb_properties,comments" --data-urlencode "sysparm_display_value=all" --data-urlencode "sysparm_exclude_reference_link=true" | jq '.result'
```
