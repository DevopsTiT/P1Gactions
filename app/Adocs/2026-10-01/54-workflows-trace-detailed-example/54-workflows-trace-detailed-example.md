# Detailed Trace Example For P-261090

## Decision tree

```
Follow one problem through both workflows
 OPEN  T1 extract-event-tags   → read event, call Problems API, clean tags
       T2 resolve-snow-values  → 7 SILVA GETs: server → technical service → no offering
                                 → past tickets → offering cfbf255f → business service 37273dbc
       T3 build-payload        → SILVA body + PD body, decision = create
       T4a preview-silva       → GET duplicate: none → ready
       T4b preview-pd          → 5 checks OK → ready
       T5a post-silva          → GET duplicate: none → POST → INC30341416
       T5b trigger-pd          → POST enqueue → 202 success
 CLOSE T1 prepare-close        → event CLOSED, API CLOSED → is_closed true, duration
       T2a close-silva         → 5 sys_choice GETs → GET incident → PATCH → Resolved
       T2b close-pd            → POST enqueue resolve → 202 success
```

## Short takeaway

| Question | Answer |
|---|---|
| What is this? | One complete example run, call by call, with inputs, requests, responses and outputs. |
| Which problem? | P-261090 on ts12.hk.intraxa, which became INC30341416. |
| Are the values real? | Problem id, host, incident number, offering cfbf255f, business service 37273dbc, company AXA XL, caller 8ddef691 are from our runs. Other ids, times and tag values are made up to show the shape and are marked `<...>` or "example". |
| How many outside calls in total? | OPEN: 1 Dynatrace, 9 SILVA, 1 PagerDuty. CLOSE: 1 Dynatrace, 7 SILVA, 1 PagerDuty. |

## Summary

This follows P-261090 from the moment Davis opens it to the moment it closes. For every task you see: which functions run in which order, the exact HTTP call, a trimmed answer, what the code decides from it, and the JSON the task returns. Compare it with your real execution: open each task's Result in Dynatrace, and task 2's `steps` list should look like section A2.

---

# Part A: OPEN run

## A0. The trigger event

Davis opens the problem. The trigger filter `DAVIS_PROBLEM AND ACTIVE AND CREATED` matches, and the workflow starts with this event (trimmed, example values marked):

```json
{
  "event.kind": "DAVIS_PROBLEM",
  "event.id": "<internal-problem-id>",
  "display_id": "P-261090",
  "event.status": "ACTIVE",
  "event.status_transition": "CREATED",
  "event.name": "Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa",
  "event.category": "ERROR",
  "root_cause_entity_name": "ts12.hk.intraxa",
  "affected_entity_names": ["ts12.hk.intraxa"],
  "affected_entity_types": ["dt.entity.host"],
  "dt.security_context": ["<example: ALJ_PRE>"],
  "maintenance.is_under_maintenance": false,
  "entity_tags": ["<example: env:PRE>", "host:ts12.hk.intraxa"]
}
```

## A1. Task 1 `extract-event-tags`

| # | Function call | Input | Result |
|---|---|---|---|
| 1 | `execution(executionId)` | the run id | `ex` handle |
| 2 | `ex.event()` | | the event above |
| 3 | `usedSample` check | `event.kind` exists | false, so the real event is used |
| 4 | `getEnvironmentUrl()` | | `https://<env>.apps.dynatrace.com` |
| 5 | `problemsClient.getProblem({ problemId: "<internal-problem-id>" })` | | API call below |

API call 1 (Dynatrace):

```
GET /api/v2/problems/<internal-problem-id>
→ 200
{
  "displayId": "P-261090",
  "title": "Error in the Windows Application Log ...",
  "status": "OPEN",
  "rootCauseEntity": { "name": "ts12.hk.intraxa" },
  "entityTags": [ { "key": "host", "value": "ts12.hk.intraxa", "stringRepresentation": "host:ts12.hk.intraxa" } ],
  "evidenceDetails": { "details": [] }
}
```

Then the helpers run (no network):

| # | Function | Input | Output |
|---|---|---|---|
| 6 | tag merge loop | event tags + API tags | `rawTags` without duplicates |
| 7 | `parseTag()` for each | `"host:ts12.hk.intraxa"` | `{key:"host", value:"ts12.hk.intraxa"}` |
| 8 | `allByKey(parsed, group tests)` | | `[]` (no group tags on this host) |
| 9 | `findByKey(parsed, SERVICE_TAG_KEYS)` | | `null` (no service tag) |
| 10 | `allByKey(parsed, env tests)` then `envLabel("PRE")` | | `"Pre-Production"` from tag env |
| 11 | `findByKey(parsed, k => k === "host")` | | `ts12.hk.intraxa` |
| 12 | app code: tag, else `[CODE.ENV]` prefix | name has no `[...]` prefix | `null` |
| 13 | maintenance check | `false` | `{value:false}` |
| 14 | `ciNames` cleanup | `["ts12.hk.intraxa"]` | `["ts12.hk.intraxa"]` |

Task 1 returns (trimmed):

```json
{
  "usedSample": false,
  "problemApi": "ok",
  "dynatrace_alert": {
    "service_name": "ts12.hk.intraxa",
    "event_name": "Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa",
    "problem_id": "P-261090",
    "problem_url": "https://<env>.apps.dynatrace.com/ui/apps/dynatrace.davis.problems/problem/<internal-problem-id>",
    "host": "ts12.hk.intraxa",
    "environment": "Pre-Production",
    "maintenance": false
  },
  "snow_inputs": {
    "group_candidates": [],
    "service_tag": null,
    "environment": { "tag_value": "PRE", "label": "Pre-Production", "from": "tag env" },
    "app_code": null,
    "host": "ts12.hk.intraxa",
    "db_or_entity_names": ["ts12.hk.intraxa"]
  }
}
```

## A2. Task 2 `resolve-snow-values`

Reads task 1 with `ex.result("extract-event-tags")`. No group tag, no service tag, no app code, so the server path is used.

Every SILVA call goes through `getRows(label, table, query, fields, limit)`:

```
GET https://silvastg.service-now.com/api/now/v2/table/<table>
    ?sysparm_query=<encoded query>
    &sysparm_fields=<fields>
    &sysparm_display_value=all&sysparm_exclude_reference_link=true&sysparm_limit=<n>
Authorization: Basic <base64 user:password>
```

### Call by call

**SILVA call 1: find the server** (function `findCis` → `getRows`)

```
table: cmdb_ci
query: name=ts12.hk.intraxa^ORname=ts12.hk.intraxa^ORname=ts12^ORfqdn=ts12.hk.intraxa
       ^ORfqdn=ts12.hk.intraxa^ORfqdn=ts12.axa-id.intraxa ... ^ORname=ts12.intraxa
→ 200, 1 row
{ "sys_id": {"value":"<TS12_ID>"}, "name": {"display_value":"ts12"},
  "fqdn": {"display_value":"ts12.hk.intraxa"}, "sys_class_name": {"value":"cmdb_ci_win_server"},
  "business_service": {"value":""}, "service": {"value":""},
  "support_group": {"value":"<SERVER_TEAM_ID>", "display_value":"<server team>"},
  "company": {"value":"<COMPANY_ID>", "display_value":"AXA XL"} }
```

`active()` picks this row. `add()` stores it in `found`.

**SILVA call 2: CI by name** (same function, names loop)

```
table: cmdb_ci   query: name=ts12.hk.intraxa
→ 200, 0 or 1 row (same server, already in found, so skipped)
```

`findCis` returns `[ts12]`.

**SILVA call 3: services linked to the server** (`servicesForCi` → `getRows`)

```
table: svc_ci_assoc   query: ci_id=<TS12_ID>
→ 200, 1 row  { "service_id": {"value":"<TECH_SVC_ID>"} }
```

**SILVA call 4: parent services** (`servicesForCi` → `getRows`)

```
table: cmdb_rel_ci   query: child=<TS12_ID>
→ 200, 0 rows
```

`servicesForCi` returns `[{id:"<TECH_SVC_ID>", via:"svc_ci_assoc"}]`.

**SILVA call 5: load that service** (`serviceById` → `getRows`)

```
table: cmdb_ci_service   query: sys_id=<TECH_SVC_ID>
→ 200, 1 row
{ "name": {"display_value":"<example: Technology Management Service>"},
  "sys_class_name": {"value":"cmdb_ci_service"},
  "assignment_group": {"value":"<TECH_TEAM_ID>", "display_value":"<technical team>"},
  "company": {"value":"<COMPANY_ID>", "display_value":"AXA XL"} }
```

`service` is set; `method = "CI ts12 -> svc_ci_assoc"`. Paths C, D, E are skipped because a service was found. The "switch to a service with offerings" block is skipped because there is only one CI service.

**Group choice** (no network, `GROUP_ORDER` loop)

| Source | Value | Used? |
|---|---|---|
| tag | null | no |
| enrichment | `<technical team>` from the service found in call 5 | yes, first hit |

Note: the group is chosen at this point, before the business service is replaced in call 8. So the team comes from the technical service, not from 37273dbc. Company is chosen later, so it uses 37273dbc.

**SILVA call 6: offerings of that service** (`getRows`)

```
table: service_offering   query: parent=<TECH_SVC_ID>
→ 200, 0 rows   (technical services have no offering)
```

`envMatch([])` returns nothing. No offering yet.

**SILVA call 7: past tickets on this server** (`getRows`)

```
table: incident
query: u_configuration_item=<TS12_ID>^cmdb_ciISNOTEMPTY^ORDERBYDESCsys_created_on
limit: 20
→ 200, 20 rows, each like
{ "number": {"display_value":"INC303....."}, "cmdb_ci": {"value":"cfbf255f..."},
  "u_business_service": {"value":"37273dbc..."} }
```

Count by offering: `{ "cfbf255f...": 20 }`. Best = `cfbf255f...`.

**SILVA call 8: load the offering** (`getRows`)

```
table: service_offering   query: sys_id=cfbf255f...
→ 200, 1 row
{ "name": {"display_value":"<offering name>"}, "u_environment": {"display_value":"<env>"},
  "parent": {"value":"37273dbc..."} }
```

`offeringFrom = "incident history on host CI (20 of 20 recent incidents)"`. Parent `37273dbc` differs from `<TECH_SVC_ID>`, so:

**SILVA call 9: load the real business service** (`serviceById`)

```
table: cmdb_ci_service   query: sys_id=37273dbc...
→ 200, 1 row
{ "name": {"display_value":"<business service name>"},
  "company": {"value":"<AXA_XL_ID>", "display_value":"AXA XL"} }
```

`service` replaced; `method += " -> replaced by <business service name> (business service of the history offering)"`.

**Company** (no network): `val(service, "company")` exists, so company = AXA XL from `servicenow_enrichment.company`.

### Task 2 `steps` output (what you will see)

| step | table | status | matches |
|---|---|---|---|
| host by name or fqdn | cmdb_ci | 200 | 1 |
| ci exact ts12.hk.intraxa | cmdb_ci | 200 | 0 or 1 |
| svc_ci_assoc | svc_ci_assoc | 200 | 1 |
| cmdb_rel_ci | cmdb_rel_ci | 200 | 0 |
| service by sys_id | cmdb_ci_service | 200 | 1 |
| offerings of service | service_offering | 200 | 0 |
| offering from incident history | incident | 200 | 20 |
| history offering | service_offering | 200 | 1 |
| service by sys_id | cmdb_ci_service | 200 | 1 |

### Task 2 returns (trimmed)

```json
{
  "snow_required": {
    "default_set_used": false,
    "assignment_group": { "name": "<technical team>", "sys_id": "<TECH_TEAM_ID>", "from": "servicenow_enrichment.assignment_group" },
    "business_service": { "name": "<business service name>", "sys_id": "37273dbc...", "from": "CI ts12 -> svc_ci_assoc -> replaced by ..." },
    "service_offering": { "name": "<offering name>", "sys_id": "cfbf255f...", "parent_id": "37273dbc...", "from": "incident history on host CI (20 of 20 recent incidents)" },
    "company": { "name": "AXA XL", "sys_id": "<AXA_XL_ID>", "from": "servicenow_enrichment.company" },
    "cmdb_ci": { "name": "ts12", "sys_id": "<TS12_ID>", "class": "Windows Server", "fqdn": "ts12.hk.intraxa" },
    "environment": { "tag_value": "PRE", "label": "Pre-Production", "from": "tag env" }
  },
  "servicenow_enrichment": { "found": true, "sys_id": "37273dbc...", "company": "AXA XL", "company_id": "<AXA_XL_ID>" }
}
```

## A3. Task 3 `build-payload` (no network)

| # | Code step | Result |
|---|---|---|
| 1 | `ex.result` task 1 and task 2 | `a`, `req`, `en` |
| 2 | target = CI FQDN | `ts12.hk.intraxa` |
| 3 | short description | `[DYNATRACE JAPAN][ts12.hk.intraxa] - Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa` (cut to 160) |
| 4 | fields list → `snowIncident` | body below |
| 5 | missing check | none |
| 6 | decision | `{create_incident:true, reason:"ok"}` |
| 7 | PagerDuty body | dedup `dt-problem-P-261090`, severity `warning` (impact is not Infrastructure in this example) |

SILVA body built:

```json
{
  "caller_id": "8ddef691fb34cf547b0dfe7b4eefdcbc",
  "u_on_behalf_of": "8ddef691fb34cf547b0dfe7b4eefdcbc",
  "contact_type": "event",
  "company": "<AXA_XL_ID>",
  "u_environment": "Pre-Production",
  "u_business_service": "37273dbc...",
  "cmdb_ci": "cfbf255f...",
  "u_configuration_item": "<TS12_ID>",
  "category": "other",
  "subcategory": "other",
  "impact": "4",
  "urgency": "4",
  "assignment_group": "<TECH_TEAM_ID>",
  "short_description": "[DYNATRACE JAPAN][ts12.hk.intraxa] - Error in the Windows Application Log ...",
  "description": "Error in the Windows Application Log ...\n\nAdditional Information:\nproblem_displayId: P-261090\n...",
  "correlation_id": "P-261090"
}
```

## A4. Task 4a `preview-silva-incident`

| # | Code step | Result |
|---|---|---|
| 1 | `FORM.map` field check | 15 OK, `u_configuration_item` OK |
| 2 | duplicate GET (call 10 below) | none |
| 3 | `problems` | `[]` |
| 4 | `open_v7_would` | `CREATE incident` |

SILVA call 10:

```
GET .../incident?sysparm_query=correlation_id=P-261090^active=true
    &sysparm_fields=number,state,assignment_group&sysparm_display_value=true&sysparm_limit=1
→ 200 { "result": [] }
```

Returns `{ "ready": true, "open_v7_would": "CREATE incident", "problems": [], "duplicate_check": {"checked":true,"http":200,"open_incident":""} }`.

## A5. Task 4b `preview-pagerduty` (no network)

| Check | Value | Status |
|---|---|---|
| event_action | trigger | OK |
| dedup_key | dt-problem-P-261090 | OK |
| payload.summary | 120 characters | OK |
| payload.source | ts12.hk.intraxa | OK |
| payload.severity | warning | OK |

Returns `{ "ready": true, "open_v7_would": "SEND trigger (in parallel with the SILVA POST)" }`.

## A6. Task 5a `post-silva-incident`

| # | Code step | Result |
|---|---|---|
| 1 | gate: decision | pass |
| 2 | gate: preview problems | pass |
| 3 | gate: sample | pass (real event) |
| 4 | duplicate GET (call 11) | none |
| 5 | DRY_RUN | false |
| 6 | POST (call 12) | created |

SILVA call 11: same GET as call 10 → `{ "result": [] }`.

SILVA call 12:

```
POST https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_display_value=all&sysparm_exclude_reference_link=true
Content-Type: application/json
<body from A3>
→ 201
{ "result": {
    "number": {"display_value":"INC30341416"},
    "sys_id": {"value":"<INC_SYS_ID>"},
    "state": {"value":"1","display_value":"New"},
    "assignment_group": {"display_value":"<technical team>"},
    "u_business_service": {"display_value":"<business service name>"},
    "cmdb_ci": {"display_value":"<offering name>"},
    "u_configuration_item": {"display_value":"ts12"},
    "u_environment": {"display_value":"Pre-Production"} } }
```

Returns:

```json
{ "action": "created", "number": "INC30341416", "sys_id": "<INC_SYS_ID>", "state": "New",
  "correlation_id": "P-261090",
  "url": "https://silvastg.service-now.com/nav_to.do?uri=incident.do?sys_id=<INC_SYS_ID>" }
```

## A7. Task 5b `trigger-pagerduty`

| # | Code step | Result |
|---|---|---|
| 1 | gates: decision, preview ready, sample | pass |
| 2 | copy body, set `routing_key`, add `links` | |
| 3 | POST (PD call 1) | triggered |

```
POST https://events.pagerduty.com/v2/enqueue
{ "routing_key": "<routing key>", "event_action": "trigger", "dedup_key": "dt-problem-P-261090",
  "client": "Dynatrace", "client_url": "<problem url>",
  "links": [ { "href": "<problem url>", "text": "Dynatrace P-261090" } ],
  "payload": { "summary": "[DYNATRACE JAPAN][ts12.hk.intraxa] - Error ...", "source": "ts12.hk.intraxa",
               "severity": "warning", "group": "Pre-Production", "component": "ts12.hk.intraxa",
               "custom_details": { "problem_id": "P-261090", "snow_correlation_id": "P-261090" } } }
→ 202 { "status": "success", "message": "Event processed", "dedup_key": "dt-problem-P-261090" }
```

Returns `{ "action": "triggered", "status": "success", "dedup_key": "dt-problem-P-261090", "snow_correlation_id": "P-261090" }`.

---

# Part B: CLOSE run

## B0. The close event

```json
{
  "event.kind": "DAVIS_PROBLEM",
  "event.id": "<internal-problem-id>",
  "display_id": "P-261090",
  "event.status": "CLOSED",
  "event.status_transition": "RESOLVED",
  "event.start": "<example: 2026-10-01T09:00:00Z>",
  "event.end": "<example: 2026-10-01T10:12:00Z>",
  "event.name": "Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa",
  "root_cause_entity_name": "ts12.hk.intraxa"
}
```

Trigger Event state "closed" and filter `event.status == "CLOSED"` both match.

## B1. Task 1 `prepare-close`

| # | Function | Result |
|---|---|---|
| 1 | `ex.event()` | event above, `usedSample` false |
| 2 | `getProblem` (Dynatrace call) | `status: "CLOSED"`, `startTime`, `endTime` in ms |
| 3 | `toMs()` on start and end | milliseconds |
| 4 | `duration(end - start)` | `"1 h 12 min"` (example) |
| 5 | `is_closed` | API status CLOSED → true |

Returns:

```json
{
  "is_closed": true,
  "closed_check": "event.status=CLOSED, transition=RESOLVED, problems api=CLOSED",
  "problem_id": "P-261090",
  "correlation_id": "P-261090",
  "dedup_key": "dt-problem-P-261090",
  "title": "Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa",
  "where": "ts12.hk.intraxa",
  "start_time": "2026-10-01T09:00:00.000Z",
  "end_time": "2026-10-01T10:12:00.000Z",
  "duration": "1 h 12 min",
  "used_sample_event": false
}
```

## B2. Task 2a `close-silva-incident`

| # | Function | SILVA call | Answer | Result |
|---|---|---|---|---|
| 1 | `choiceValue("state","Resolved")` | `GET sys_choice name=incident^element=state^inactive=false^language=en` | rows like `{value:"1",label:"New"}`, `{value:"2",label:"In Progress"}`, `{value:"6",label:"Resolved"}` (example values) | `state.value = "6"` |
| 2 | `choiceValue("close_code","Solved (Permanently)")` | `GET sys_choice ...element=close_code` | contains "Solved (Permanently)" | `closeCode.value = "Solved (Permanently)"` |
| 3 | `softChoice("state","In Progress")` | `GET sys_choice ...element=state` | same list | `"2"` |
| 4 | `softChoice("incident_state","Resolved", "6")` | `GET sys_choice ...element=incident_state` | list for incident_state | `"6"` (example) |
| 5 | `softChoice("incident_state","In Progress", "2")` | same | | `"2"` |
| 6 | `getRows("incident", ...)` | `GET incident correlation_id=P-261090^active=true^ORDERBYDESCsys_created_on` limit 5 | 1 row: INC30341416, state 1 New, incident_state 1 New, close_code empty | `all = [INC30341416]` |
| 7 | `isResolved` filter | | not resolved | `open = [INC30341416]` |
| 8 | gate: sample | | real event | continue |

Build the notes and the first body:

| Code step | Result |
|---|---|
| `closeNotes` | "Dynatrace problem P-261090 closed automatically at 2026-10-01T10:12:00.000Z. Duration: 1 h 12 min ..." |
| `note` (work note) | "=== Dynatrace problem closed (P-261090) === ... PagerDuty : resolved with dedup_key dt-problem-P-261090" |
| `notesDone` | false (close_code empty) |
| `firstBody` | state, incident_state, close_code, close_notes, work_notes |

SILVA call 7 (`patch`):

```
PATCH https://silvastg.service-now.com/api/now/v2/table/incident/<INC_SYS_ID>?sysparm_display_value=all&sysparm_exclude_reference_link=true
{ "state": "6", "incident_state": "6", "close_code": "Solved (Permanently)",
  "close_notes": "Dynatrace problem P-261090 closed automatically at ...",
  "work_notes": "=== Dynatrace problem closed (P-261090) === ..." }
→ 200
{ "result": { "state": {"value":"6","display_value":"Resolved"},
              "incident_state": {"value":"6","display_value":"Resolved"} } }
```

`isResolved("6","6")` → true. The In Progress fallback is not needed.

Returns:

```json
{
  "action": "resolved",
  "correlation_id": "P-261090",
  "value_check": { "state": "OK (Resolved)", "in_progress": "OK (In Progress)", "incident_state": "OK (Resolved)", "close_code": "OK (Solved (Permanently))" },
  "incidents": [ {
    "number": "INC30341416", "action": "resolved",
    "state_before": "New", "state_after": "Resolved", "incident_state_after": "Resolved",
    "worked_with": "direct to Resolved (state + incident_state)",
    "attempts": [ { "step": "direct to Resolved (state + incident_state)", "http": 200, "ok": true, "state_label": "Resolved", "incident_state": "Resolved" } ]
  } ]
}
```

In SILVA Activities you then see "Incident State Resolved was New", Resolved by Dynatrace JP, and the Resolver Group, as in your screenshot.

## B3. Task 2b `close-pagerduty` (runs at the same time as 2a)

| # | Code step | Result |
|---|---|---|
| 1 | gate: is_closed | true |
| 2 | gate: dedup key has an id | `dt-problem-P-261090` |
| 3 | gate: sample | real |
| 4 | POST (PD call) | resolved |

```
POST https://events.pagerduty.com/v2/enqueue
{ "routing_key": "<routing key>", "event_action": "resolve", "dedup_key": "dt-problem-P-261090" }
→ 202 { "status": "success", "message": "Event processed", "dedup_key": "dt-problem-P-261090" }
```

Returns `{ "action": "resolved", "status": "success", "dedup_key": "dt-problem-P-261090", "snow_correlation_id": "P-261090" }`.

---

## Full call count for this example

| Workflow | Dynatrace | SILVA GET | SILVA POST | SILVA PATCH | PagerDuty |
|---|---|---|---|---|---|
| OPEN | 1 | 11 (9 in task 2, 1 in 4a, 1 in 5a) | 1 | 0 | 1 |
| CLOSE | 1 | 6 (5 sys_choice, 1 incident) | 0 | 1 | 1 |

## What would change in other cases

| Case | Difference in the trace |
|---|---|
| Host has a group tag | Task 2 makes a `sys_user_group` GET first and the team comes from the tag. |
| Server is linked straight to a business service with an offering | Calls 7 to 9 (history) are skipped; offering comes from call 6. |
| Problem in maintenance | Task 3 decision false; 5a and 5b return `skipped`. |
| Ticket already open | 4a shows `SKIP (already open: INC...)`; 5a returns `exists`. |
| SILVA refuses New to Resolved | CLOSE 2a makes 2 more PATCHes (In Progress, then Resolved); `attempts` has 3 rows. |
| Manual Run | `usedSample` true; send tasks return `skipped` unless `ALLOW_SAMPLE_POST = true`. |

## Data flow map

```
event P-261090 ─► T1 (getProblem) ─► snow_inputs{host ts12, env PRE}
  ─► T2: cmdb_ci ts12 → svc_ci_assoc → tech service → offerings 0 → history 20/20 cfbf255f
         → offering parent 37273dbc → company AXA XL
  ─► T3 body (correlation_id P-261090) + PD body (dt-problem-P-261090)
  ─► T4a dup none ─► T5a POST → INC30341416
  ─► T4b ready     ─► T5b trigger 202
close P-261090 ─► T1 is_closed ─► T2a sys_choice x5 → incident → PATCH Resolved
                               ─► T2b resolve 202
```

## Investigation

| Source | Used for |
|---|---|
| OPEN and CLOSE code (seq 36, seq 45) | Function order and request shapes |
| Seq 35 preview results | Offering cfbf255f from history 20 of 20, business service 37273dbc, company AXA XL |
| INC30341416 screenshots | Resolved through incident_state, Resolved by Dynatrace JP |

## Result

Use this as the reference picture of a healthy run. Compare it with your real execution: task 2 `steps` should match section A2, and CLOSE 2a `attempts` should show one PATCH.

## Related files

| File | What it is |
|---|---|
| `51-workflows-functions-api-traces/` | Function inventory and call list this example follows |
| `47-open-close-e2e-api-data-flow/` | E2E overview |
| `54.sh` | Commands to pull the real results of each task for comparison |

## Commands

See [`54.sh`](54.sh).
