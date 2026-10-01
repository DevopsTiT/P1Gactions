# Open And Close Workflows End To End

## Decision tree

```
Something went wrong end to end. Where?
 No execution at all?
   → workflow Draft? → Deploy
   → trigger wrong? → OPEN: ACTIVE + CREATED; CLOSE: Event state "closed"
 Task error "not allowed" or fetch failed?
   → External requests allowlist: silvastg.service-now.com, events.pagerduty.com
 OPEN task 2 picked wrong service, group or offering?
   → read task 2 "steps" and "*_candidates" → set SERVICE_MAP or GROUP_MAP
 OPEN 5a skipped?
   → reason "missing" → task 3 decision; "preview found problems" → 4a field_check
   → "exists" → ticket already open for this problem (correct behaviour)
 OPEN 5a red (SILVA POST failed 4xx)?
   → 401 login, 403 role or ACL, 400 bad field value
 CLOSE 2a "no open unresolved incident"?
   → OPEN skipped that problem, or someone resolved it by hand
 CLOSE 2a "state still New"?
   → check incident_state in sys_choice, try STEP_THROUGH_IN_PROGRESS
 PagerDuty not resolved?
   → dedup_key in OPEN 5b output must equal CLOSE 2b output
```

## Short takeaway

| Question | Answer |
|---|---|
| How many systems are involved? | Three: Dynatrace (event and Problems API), SILVA ServiceNow stg (Table API), PagerDuty (Events API v2). |
| How do tasks pass data? | Each task returns JSON; later tasks read it with `ex.result("task-name")`. |
| How many SILVA calls does OPEN make? | About 10 to 30 GETs in task 2, 1 GET in 4a, 1 GET plus 1 POST in 5a. |
| How many SILVA calls does CLOSE make? | 5 `sys_choice` GETs, 1 incident GET, then 1 to 3 PATCHes per incident. |
| How many PagerDuty calls? | One POST in each workflow: trigger in OPEN, resolve in CLOSE. |
| What links OPEN and CLOSE? | SILVA `correlation_id` = display id, and PagerDuty `dedup_key` = `dt-problem-<display id>`. |
| How does each system authenticate? | Dynatrace SDK uses the workflow's identity. SILVA uses Basic auth. PagerDuty uses the routing key in the body. |

## Summary

A Davis problem opens. OPEN reads it from Dynatrace, asks SILVA (read only) for the right group, service, offering and host, builds two bodies, previews them, and then creates one SILVA incident and one PagerDuty alert. Both are tagged with the problem's display id. When the problem closes, CLOSE reads the same display id, finds the SILVA incident by `correlation_id`, sets it to Resolved, and sends PagerDuty a resolve with the same `dedup_key`.

---

## 1. The systems and how each one authenticates

| System | Base URL | How the workflow logs in | Used by |
|---|---|---|---|
| Dynatrace automation engine | internal (`@dynatrace-sdk/automation-utils`) | Workflow's own execution context | Every task, to read the event and other task results |
| Dynatrace Problems API v2 | your environment, through `problemsClient` | Workflow actor identity; needs problem read permission | OPEN task 1, CLOSE task 1 |
| SILVA ServiceNow stg | `https://silvastg.service-now.com` | `Authorization: Basic base64(Tech_DynatraceJP_WS:password)` | OPEN tasks 2, 4a, 5a; CLOSE task 2a |
| PagerDuty Events API v2 | `https://events.pagerduty.com/v2/enqueue` | `routing_key` inside the JSON body; no auth header | OPEN 5b, CLOSE 2b |

Before any outside call works, both hosts must be on the External requests allowlist (Settings, General, External requests).

## 2. Common SILVA Table API shape

Every SILVA call in both workflows uses the same URL pattern:

```
GET   {BASE}/api/now/v2/table/{table}?sysparm_query=...&sysparm_fields=...&sysparm_display_value=all&sysparm_exclude_reference_link=true&sysparm_limit=N
POST  {BASE}/api/now/v2/table/incident?sysparm_display_value=all&sysparm_exclude_reference_link=true
PATCH {BASE}/api/now/v2/table/incident/{sys_id}?sysparm_display_value=all&sysparm_exclude_reference_link=true
```

| Parameter | What it means | Why the workflow uses it |
|---|---|---|
| `sysparm_query` | Filter, written in ServiceNow encoded query syntax (`^` = AND, `^OR` = OR). | Finds the exact rows. |
| `sysparm_fields` | Which columns to return. | Smaller, faster answers. |
| `sysparm_display_value=all` | Return each reference as `{value, display_value}`. | `val()` takes the sys_id, `dv()` takes the readable name. |
| `sysparm_exclude_reference_link=true` | Leave out link URLs. | Cleaner JSON. |
| `sysparm_limit` | Maximum rows. | Stops huge answers. |

Example answer row:

```json
{ "result": [ { "sys_id": {"value": "cfbf255f...", "display_value": "cfbf255f..."},
                "assignment_group": {"value": "a1b2...", "display_value": "Ops_Middleware_Monitoring_AXAJP"} } ] }
```

---

# Part A: OPEN end to end

## A0. Overall picture

```
Dynatrace Davis ── problem P-261090 CREATED (ACTIVE) ──► Workflow trigger (filter ACTIVE + CREATED)
                                                           │
 [1] extract-event-tags ──► ex.event() ──► Problems API getProblem
         │ returns dynatrace_alert + snow_inputs
 [2] resolve-snow-values ──► SILVA GET x N (groups, CIs, services, offerings, incident history)
         │ returns snow_required + servicenow_enrichment
 [3] build-payload (no network)
         │ returns decision + snow_incident_payload + pagerduty_payload
   ┌─────┴──────────────────────────────┐
 [4a] preview-silva-incident           [4b] preview-pagerduty (no network)
      SILVA GET incident (duplicate)         │ returns ready + checks
      │ returns ready + problems             │
 [5a] post-silva-incident              [5b] trigger-pagerduty
      SILVA GET incident (duplicate)         PD POST /v2/enqueue (trigger)
      SILVA POST incident                    │ returns triggered + dedup_key
      │ returns number INC30341416
```

## A1. Trigger: Dynatrace to workflow

| Step | Data | Notes |
|---|---|---|
| Davis opens a problem | Event with `event.kind=DAVIS_PROBLEM`, `event.status=ACTIVE`, `event.status_transition=CREATED`. | |
| Trigger checks it | Filter on lines 35 to 37 of the OPEN file. | Any update event to the same problem is ignored. |
| Workflow starts | Execution gets an `executionId`; the event is attached. | Tasks read it with `ex.event()`. |

Main event fields the workflow reads:

| Event field | Example | Used for |
|---|---|---|
| `event.id` | internal problem id | Problems API call, problem URL |
| `display_id` | P-261090 | SILVA `correlation_id`, PD `dedup_key` |
| `event.name` | Error in the Windows Application Log ... | Ticket title |
| `event.description` | text with "10.29 %" | Description, error rate |
| `entity_tags` | `env:PRE`, `host:...`, `dt.cost.product:...` | Environment, host, app code, group tags |
| `root_cause_entity_name` | ts12.hk.intraxa | Title target, CI search |
| `affected_entity_names`, `affected_entity_ids` | service or host names and ids | CI search, PD source |
| `dt.security_context` | ALJ_PRE | Environment fallback |
| `maintenance.is_under_maintenance` | false | Block ticket if true |
| `labels.alerting_profile` | ALJ NewSilvaSTG | Shown in description |

## A2. Task 1 `extract-event-tags`

| Call | Method and target | Input | Output used |
|---|---|---|---|
| Read event | `ex.event()` | executionId | All event fields above |
| Problems API | `problemsClient.getProblem({ problemId: event.id })` (REST: `GET /api/v2/problems/{problemId}`) | event.id | `entityTags`, `rootCauseEntity.name`, `evidenceDetails` (error rate), `severityLevel`, `impactLevel`, `title`, `displayId` |

What it returns (read by task 2 and task 3):

| Output key | Contains | Read by |
|---|---|---|
| `dynatrace_alert` | service name, event name, description, error rate, problem id, URL, host, environment label, app code, trigram, maintenance | task 3 |
| `snow_inputs` | group tag candidates, service tag, environment, app code, DB type, domain, trigram, region, host, CI names | task 2 |
| `tags.raw` | every tag as text | task 3 (description) |
| `dt_environment_id` | first part of the environment host name | task 3 (description) |
| `usedSample` | true when started by Run | task 3, then 4a, 4b, 5a, 5b |

## A3. Task 2 `resolve-snow-values` (SILVA, GET only)

The calls happen in this order, and most only run if the earlier ones found nothing.

| # | Purpose | Table | Query (simplified) | Takes from the answer |
|---|---|---|---|---|
| 1 | Group from `GROUP_MAP` | `sys_user_group` | `name=<group>^active=true` | group sys_id, company |
| 2 | Each group tag | `sys_user_group` | `name=<tag value>^active=true` | first group that exists = tag group |
| 3 | Service from map or tag | `cmdb_ci_service` | `name=<service>^sys_class_name!=service_offering` | business service |
| 4 | Host CI by name or FQDN | `cmdb_ci` | `name=ts12^ORfqdn=ts12.hk.intraxa^OR...` | host CI sys_id, support group, company |
| 5 | Host CI "starts with" | `cmdb_ci` | `nameSTARTSWITHts12.^ORfqdnSTARTSWITHts12.` | same, only if 4 found nothing |
| 6 | Other CI names | `cmdb_ci` | `name=<n>`, then `nameLIKE<n>` | more CIs |
| 7 | Services linked to CI | `svc_ci_assoc` | `ci_id=<ci sys_id>` | service ids |
| 8 | Parent services of CI | `cmdb_rel_ci` | `child=<ci sys_id>` | parent ids whose class is a service |
| 9 | Load each linked service | `cmdb_ci_service` | `sys_id=<id>` | business service |
| 10 | Scored searches | `cmdb_ci_service` | `nameLIKE<app code>`, `assignment_group=<g>^ORsupport_group=<g>`, DB type plus environment, trigram | candidates, best by score |
| 11 | First answer searches | `cmdb_ci_service` | `nameLIKE<app code>`, `assignment_group.nameLIKE<group>` | first matching service |
| 12 | Default service | `cmdb_ci_service` | `name=QA Platforms` | last resort |
| 13 | Offerings of the service | `service_offering` | `parent=<service sys_id>` | offering whose `u_environment` matches |
| 14 | Offering from history | `incident` | `u_configuration_item=<ci>^cmdb_ciISNOTEMPTY^ORDERBYDESCsys_created_on` (20 rows) | most used `cmdb_ci` (offering) and its `u_business_service` |
| 15 | Load history offering | `service_offering` | `sys_id=<best>` | offering and its parent |
| 16 | Default offering | `service_offering` | `nameSTARTSWITHQA Platforms - AXA GROUP OPERATIONS` | only in "default set" |
| 17 | Offering by group | `service_offering` | `assignment_group=<g>^ORsupport_group=<g>` | last resort |
| 18 | Default group | `sys_user_group` | `name=Ops_Middleware_Monitoring_AXAJP^active=true` | only if no other group |

For P-261090 the useful path was: host CI found by FQDN (call 4), then offering cfbf255f from history (call 14, 20 of 20 incidents), then business service 37273dbc as that offering's parent, and company AXA XL.

What task 2 returns:

| Output key | Contains | Read by |
|---|---|---|
| `snow_required.assignment_group` | name, sys_id, source | task 3 |
| `snow_required.business_service` | name, sys_id, method | task 3 |
| `snow_required.service_offering` | name, sys_id, environment, source | task 3 |
| `snow_required.cmdb_ci` | host CI name, sys_id, FQDN | task 3 |
| `snow_required.company` | name, sys_id, source | task 3 |
| `snow_required.environment` | label and where it came from | task 3 |
| `servicenow_enrichment` | full business service details | task 3 |
| `steps` | every call: table, query, HTTP status, matches | you, for debugging |

## A4. Task 3 `build-payload` (no network)

Inputs: `ex.result("extract-event-tags")` and `ex.result("resolve-snow-values")`.

SILVA body it builds (example values for P-261090):

| Field | Value source | Example |
|---|---|---|
| `caller_id` | setting | 8ddef691... (Dynatrace JP) |
| `u_on_behalf_of` | setting | 8ddef691... |
| `contact_type` | setting | event |
| `company` | business service company | AXA XL sys_id |
| `u_environment` | environment label | Pre-Production |
| `u_business_service` | task 2 business service | 37273dbc... |
| `cmdb_ci` | task 2 service offering | cfbf255f... |
| `u_configuration_item` | task 2 host CI | ts12 CI sys_id |
| `category`, `subcategory` | setting | other |
| `impact`, `urgency` | setting | 4 |
| `assignment_group` | task 2 group | group sys_id |
| `short_description` | prefix + target + event name | `[DYNATRACE JAPAN][ts12.hk.intraxa] - Error in ...` |
| `description` | event description + Additional Information | multi-line text |
| `correlation_id` | display id | P-261090 |

PagerDuty body it builds:

```json
{
  "routing_key": "__PD_ROUTING_KEY__",
  "event_action": "trigger",
  "dedup_key": "dt-problem-P-261090",
  "client": "Dynatrace",
  "client_url": "<problem url>",
  "payload": {
    "summary": "[DYNATRACE JAPAN][ts12.hk.intraxa] - Error in ...",
    "source": "ts12.hk.intraxa",
    "severity": "warning",
    "group": "Pre-Production",
    "component": "<trigram or service>",
    "custom_details": { "problem_id": "P-261090", "snow_correlation_id": "P-261090", "...": "..." }
  }
}
```

Decision: `create_incident = true` only when group, business service, offering, environment and title are all present and maintenance is off.

## A5. Task 4a `preview-silva-incident`

| Call | Method and target | Purpose |
|---|---|---|
| Duplicate check | `GET /api/now/v2/table/incident?sysparm_query=correlation_id=P-261090^active=true&sysparm_fields=number,state,assignment_group&sysparm_display_value=true&sysparm_limit=1` | Is there already an open ticket for this problem? |

No other network. It also checks each body field: MISSING, EMPTY, WRONG (name instead of sys_id), or OK. Output `ready` and `problems` go to 5a.

## A6. Task 4b `preview-pagerduty`

No network. It checks action, dedup key format, summary, source and severity. Output `ready` goes to 5b.

## A7. Task 5a `post-silva-incident`

| Order | Call | Details |
|---|---|---|
| 1 | Gates (no network) | Decision true, no preview problems, not a sample (unless allowed). |
| 2 | `GET incident` duplicate check | Same query as 4a. If found: return `action: exists` and stop. |
| 3 | `POST /api/now/v2/table/incident` | Body = task 3 SILVA body. Headers: Basic auth, `Content-Type: application/json`. |
| 4 | Read answer | HTTP 201 with `result.number`, `result.sys_id`, and the saved fields. Any non-2xx throws. |

Output example: `{ action: "created", number: "INC30341416", sys_id: "...", state: "New", url: ".../nav_to.do?uri=incident.do?sys_id=..." }`

## A8. Task 5b `trigger-pagerduty`

| Order | Call | Details |
|---|---|---|
| 1 | Gates | Decision true, preview ready, not a sample. |
| 2 | `POST https://events.pagerduty.com/v2/enqueue` | Body = task 3 PD body with the real `routing_key` and a `links` entry. |
| 3 | Read answer | HTTP 202 `{ "status": "success", "message": "Event processed", "dedup_key": "dt-problem-P-261090" }`. Non-2xx throws. |

PagerDuty opens an incident on the service behind the routing key. A second trigger with the same `dedup_key` while it is open only adds to the same alert.

---

# Part B: CLOSE end to end

## B0. Overall picture

```
Dynatrace Davis ── problem P-261090 CLOSED ──► Workflow trigger (Event state "closed", filter CLOSED)
                                                 │
 [1] prepare-close ──► ex.event() ──► Problems API getProblem
         │ returns is_closed, correlation_id, dedup_key, duration, cause
   ┌─────┴───────────────────────────────┐
 [2a] close-silva-incident             [2b] close-pagerduty
      SILVA GET sys_choice x5               PD POST /v2/enqueue (resolve)
      SILVA GET incident by correlation_id  │ returns resolved
      SILVA PATCH incident (1 to 3 times)
      │ returns resolved + attempts
```

## B1. Trigger

| Step | Data |
|---|---|
| Davis closes P-261090 | Event with `event.status=CLOSED`, same `display_id` and `event.id`. |
| Trigger | Event state "closed" (`triggerOn: close`) plus filter `event.status == "CLOSED"`. |

## B2. Task 1 `prepare-close`

| Call | Method and target | Takes from the answer |
|---|---|---|
| Read event | `ex.event()` | `event.id`, `display_id`, `event.status`, `event.status_transition`, `event.start`, `event.end`, `event.name`, `root_cause_entity_name` |
| Problems API | `getProblem({ problemId })` (REST `GET /api/v2/problems/{id}`) | `status`, `startTime`, `endTime`, `title`, `rootCauseEntity`, `affectedEntities` |

Returns: `is_closed`, `correlation_id` (P-261090), `dedup_key` (dt-problem-P-261090), `title`, `where`, `start_time`, `end_time`, `duration`, `problem_url`, `used_sample_event`. Both 2a and 2b read this.

## B3. Task 2a `close-silva-incident`

| Order | Call | Query or body | Takes from the answer |
|---|---|---|---|
| 1 | `GET sys_choice` | `name=incident^element=state^inactive=false^language=en` | stored value for "Resolved" |
| 2 | `GET sys_choice` | `element=close_code` | stored value for "Solved (Permanently)" |
| 3 | `GET sys_choice` | `element=state` (again, for In Progress) | stored value for "In Progress" |
| 4 | `GET sys_choice` | `element=incident_state` | stored value for Resolved on incident_state |
| 5 | `GET sys_choice` | `element=incident_state` (In Progress) | stored value for In Progress on incident_state |
| 6 | `GET incident` | `correlation_id=P-261090^active=true^ORDERBYDESCsys_created_on`, limit 5 | sys_id, number, state, incident_state, close_code, group, service, offering, CI |
| 7 | `PATCH incident/{sys_id}` | see body below | new state and incident_state |
| 8 | `PATCH` (only if 7 did not resolve) | `{ state: In Progress, incident_state: In Progress }` | |
| 9 | `PATCH` (only after 8) | `{ state: Resolved, incident_state: Resolved, close_code }` | final state |

First PATCH body:

```json
{
  "state": "<Resolved value>",
  "incident_state": "<Resolved value>",
  "close_code": "Solved (Permanently)",
  "close_notes": "Dynatrace problem P-261090 closed automatically at ...\nDuration: ...\nCause: ...\nRecovery confirmed by Dynatrace ...",
  "work_notes": "=== Dynatrace problem closed (P-261090) ===\nDuration ...\nAssignment group ...\nPagerDuty : resolved with dedup_key dt-problem-P-261090"
}
```

SILVA answer (HTTP 200): the updated record. Success is counted only if `state` or `incident_state` now equals Resolved. On INC30341416 SILVA logged "Incident State Resolved was New" and set Resolved by Dynatrace JP and the Resolver Group itself.

## B4. Task 2b `close-pagerduty`

| Order | Call | Details |
|---|---|---|
| 1 | Gates | is_closed, dedup key has an id, not a sample. |
| 2 | `POST https://events.pagerduty.com/v2/enqueue` | `{ "routing_key": "...", "event_action": "resolve", "dedup_key": "dt-problem-P-261090" }` |
| 3 | Answer | HTTP 202 `{ "status": "success", "dedup_key": "dt-problem-P-261090" }`. If no open alert has that key, PagerDuty just ignores it. |

---

## 3. One problem, full timeline (P-261090)

| Time | System | What happens | Key data |
|---|---|---|---|
| T0 | Dynatrace | Davis opens P-261090 on ts12.hk.intraxa. | event.status ACTIVE, CREATED |
| T0 | OPEN 1 | Reads event and Problems API. | tags, host, environment |
| T0 | OPEN 2 | SILVA GETs find host CI, offering (history), business service, group, company. | sys_ids |
| T0 | OPEN 3 | Builds both bodies. | correlation_id P-261090, dedup_key dt-problem-P-261090 |
| T0 | OPEN 4a, 4b | Previews ready, no duplicate. | ready true |
| T0 | OPEN 5a | SILVA POST. | INC30341416, state New |
| T0 | OPEN 5b | PD trigger. | PD incident opened |
| T1 | Dynatrace | Problem closes. | event.status CLOSED |
| T1 | CLOSE 1 | Reads event and API, computes duration. | is_closed true |
| T1 | CLOSE 2a | Finds INC30341416 by correlation_id, PATCH to Resolved. | Incident State Resolved |
| T1 | CLOSE 2b | PD resolve. | PD incident resolved |

## 4. Data handoff map (which task reads what)

```
event ─► OPEN1 ─dynatrace_alert──────────────► OPEN3
               ─snow_inputs──► OPEN2 ─snow_required, enrichment─► OPEN3
OPEN3 ─snow_incident_payload, decision, used_sample─► OPEN4a, OPEN5a
OPEN3 ─pagerduty_payload, decision, used_sample─────► OPEN4b, OPEN5b
OPEN4a ─problems, ready─► OPEN5a
OPEN4b ─ready───────────► OPEN5b

event ─► CLOSE1 ─is_closed, correlation_id, title, duration, url─► CLOSE2a
                ─is_closed, dedup_key, used_sample───────────────► CLOSE2b
```

## 5. Responsibility matrix

| Component | Owns | If it fails |
|---|---|---|
| Dynatrace trigger | Starting the right workflow at the right time | Nothing runs. Check Deploy and Event state. |
| Problems API | Extra tags, times, evidence | Workflow continues with event data only (`problem_api: failed`). |
| SILVA lookups (OPEN 2) | Correct group, service, offering, CI | Wrong or missing fields; 4a shows MISSING or WRONG; 5a skips. |
| SILVA POST (OPEN 5a) | Creating the ticket | Task red with SILVA's message. PD still triggers. |
| SILVA PATCH (CLOSE 2a) | Resolving the ticket | Task red with all attempts. PD still resolves. |
| PagerDuty (OPEN 5b, CLOSE 2b) | Paging and un-paging on-call | Task red. SILVA side is not affected. |

## 6. Common issues

| Symptom | Likely cause | Fix |
|---|---|---|
| `fetch failed` or "not allowed" | Host not on the allowlist | Add `silvastg.service-now.com` and `events.pagerduty.com`. |
| SILVA 401 | Wrong user or password | Check the settings block in each SILVA task. |
| SILVA 403 | Account lacks table rights | Ask SILVA admins for read on the lookup tables and write on incident. |
| Field shows WRONG in 4a | A name was used where a sys_id is needed | Fix the map or tag so task 2 finds the record. |
| CLOSE says no open incident | OPEN skipped, or ticket already resolved | Check the OPEN run for that problem. |
| PD stays open | Different dedup_key, or 2b skipped | Compare `dedup_key` in OPEN 5b and CLOSE 2b outputs. |

## Investigation

| What I checked | Where |
|---|---|
| Every `fetch`, `getRows` and `problemsClient` call in OPEN | seq 36 file, tasks 1, 2, 4a, 5a, 5b |
| Every call in CLOSE | seq 45 file, tasks 1, 2a, 2b |
| Real P-261090 results | seq 35 preview analysis and the INC30341416 screenshots |

## Result

You now have, for each workflow: the trigger, every API call in order, the exact query or body, what comes back, and which task uses it next. Use section 6 and the decision tree when a run goes wrong.

## Related files

| File | What it is |
|---|---|
| `36-standard-flow-preview-then-post/...workflow.yaml` | OPEN |
| `45-close-direct-v5-trigger-closed/...workflow.yaml` | CLOSE |
| `46-open-close-workflows-line-by-line/` | Line-by-line walkthrough |
| `41-how-to-build-workflows-apis-discovery/41.sh` | Discovery queries |
| `47.sh` | Manual curl versions of each call |

## Commands

See [`47.sh`](47.sh). It has the same SILVA and PagerDuty calls as curl one-liners so you can replay any step by hand.
