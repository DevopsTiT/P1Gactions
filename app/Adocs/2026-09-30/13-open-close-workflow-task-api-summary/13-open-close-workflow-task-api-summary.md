# Dynatrace To SILVA And PagerDuty Workflows — Complete Summary
## OPEN v6 (5 tasks) + CLOSE v6 (3 tasks) + SILVA Table API + PagerDuty Events API

---

## Decision Tree

```
Davis problem event arrives
 │
 ├─ status ACTIVE + transition CREATED ?  → OPEN workflow
 │    1 extract-event-tags     read event + tags (+ Problems API)
 │    2 resolve-snow-values    ask SILVA: group → service → offering
 │    3 display-result         build SNOW body + PD body + decision
 │    │    maintenance on OR required field missing? → decision = NO
 │    4 post-silva-incident
 │    │    decision NO or sample?        → skipped
 │    │    open incident same key?       → exists (no new ticket)
 │    │    DRY_RUN?                      → log only
 │    │    else                          → POST incident → created
 │    5 trigger-pagerduty
 │         task 4 skipped?               → skipped
 │         task 4 exists + no resend?    → skipped
 │         else                          → POST trigger → triggered
 │
 └─ status CLOSED / RESOLVED ?  → CLOSE workflow
      1 prepare-close          build keys + close notes
      ├─ 2 resolve-silva-incident   (runs in parallel with 3)
      │      open incident found?    → PATCH state 6 → resolved
      │      only closed one found?  → already_resolved
      │      nothing found?          → not_found
      └─ 3 resolve-pagerduty
             POST resolve with same dedup_key → resolved
```

## Short Takeaway

| Question | Answer |
|---|---|
| What starts OPEN? | A new, active Davis problem |
| What starts CLOSE? | The same problem becoming closed or resolved |
| How do OPEN and CLOSE find the same ticket? | Both use `display_id` as the SILVA `correlation_id` |
| How do they find the same page? | Both use `dt-problem-<display_id>` as the PagerDuty `dedup_key` |
| How do tasks share data? | Each task `return`s an object; later tasks read it with `ex.result("<task id>")` |
| Which external systems are called? | Dynatrace Problems API, SILVA Table API, PagerDuty Events API v2 |
| Where are the secrets? | OPEN lines 318, 885, 976 and CLOSE lines 209, 311 |

## Summary

OPEN turns a Davis problem into one SILVA incident and one PagerDuty page. Task 1 reads the event, task 2 asks SILVA who owns it, task 3 builds the payloads and decides whether to send, and tasks 4 and 5 do the actual sending. CLOSE uses the same two keys to find that incident and that page again, and resolves both at the same time.

---

## 2. End-to-End Data Flow

```
Dynatrace Davis problem (event)
  │
  ├── OPEN ─────────────────────────────────────────────────────────────►
  │   [1 extract-event-tags] ── Problems API (optional) ──┐
  │        returns: dynatrace_alert, snow_inputs, tags,    │
  │                 event_properties, dt_environment_id    │
  │   [2 resolve-snow-values] ── SILVA GETs (many) ────────┤
  │        returns: snow_required (group, service,         │
  │                 offering, company, environment)        │
  │   [3 display-result]  (no API calls)                   │
  │        returns: snow_incident body, pagerduty body,    │
  │                 form_check, decision                   │
  │   [4 post-silva-incident] ── SILVA GET dup + POST ─────┤──► SILVA incident INC...
  │        returns: action, number, sys_id, url            │
  │   [5 trigger-pagerduty] ── PagerDuty POST trigger ─────┘──► PD incident (paged)
  │
  └── CLOSE ────────────────────────────────────────────────────────────►
      [1 prepare-close] ── Problems API (optional)
           returns: correlationId, dedupKey, closeNotes, workNotes
      ├─[2 resolve-silva-incident] ── SILVA GET + PATCH ──► incident state 6
      └─[3 resolve-pagerduty] ─────── PagerDuty POST resolve ──► PD resolved

  Shared keys:  correlation_id = display_id
                dedup_key      = dt-problem-<display_id>
```

---

## 3. OPEN Workflow — Full Pipeline

### 3a. Task Overview

| Step | Task ID | Its job | Runs after | Calls an API? |
|---|---|---|---|---|
| 1 | `extract-event-tags` | Read the problem and its tags into clean fields | Nothing (first) | Dynatrace Problems API (optional) |
| 2 | `resolve-snow-values` | Find the SILVA group, business service and offering | Task 1 OK | SILVA Table API, GET only |
| 3 | `display-result` | Build the incident body and the PagerDuty body, then decide | Task 2 OK | None |
| 4 | `post-silva-incident` | Create the SILVA incident unless one already exists | Task 3 OK | SILVA Table API, GET then POST |
| 5 | `trigger-pagerduty` | Page on-call | Task 4 OK | PagerDuty Events API v2 |

### 3b. Task 1 — `extract-event-tags`

**What it does, step by step:**

| Step | What happens |
|---|---|
| Get the event | Reads the trigger event. On a manual Run there is no event, so it uses `SAMPLE_EVENT` and sets `usedSample: true`. |
| Optional detail | Calls the Problems API for evidence (error rate, extra tags). A failure is recorded, not fatal. |
| Parse tags | Removes `[Context]`, splits each tag at the first `:` into key and value |
| Group candidates | Support group tag first, then specific group tags, then the default group tag |
| Environment | Environment tags, then patch environment, then security context, then the default label |
| Maintenance | Event field first, then the `AGO_Maintenance` tag |
| Names | Host, DB entity name (for example DEA10B01), root cause, best display name |
| Link | Builds the problem URL from the tenant URL |

**What it passes on (return value):**

| Field | What is inside | Who uses it |
|---|---|---|
| `usedSample` | True when running on the sample event | Tasks 3, 4 and 5 (safety guard) |
| `dynatrace_alert` | Title, status, severity, problem link, display ID, error rate | Task 3 |
| `snow_inputs` | Group candidates, environment, DB type, trigram, region, host, entity names, maintenance | Task 2 |
| `tags` | Parsed tag list | Task 3 (Additional Information) |
| `event_properties` | Every event field, up to 300 characters each | Task 3 |
| `dt_environment_id` | Tenant ID | Task 3 (Summary text) |

**API call:**

| Call | Purpose | Needs |
|---|---|---|
| `problemsClient.getProblem({ problemId: event.id })` | Extra evidence and tags | Scope `environment-api:problems:read` (still to be granted) |

### 3c. Task 2 — `resolve-snow-values`

This is the "who owns it" brain. It only reads from SILVA; it never writes.

**Order of decisions:**

| Order | Target | Method | Stops when |
|---|---|---|---|
| 1 | Group | `GROUP_MAP` name, checked in SILVA | Found |
| 2 | Group | Each tag candidate, checked in SILVA | First one found |
| 3 | Group | Keep the tag name even if SILVA did not confirm it | Tag existed |
| A | Service | `SERVICE_MAP` or a service tag, exact name | Found |
| B | Service | Find the host or DB record, then follow its link to a service | Found |
| C | Service | Up to five searches, merge, score, pick the best with at least 5 points | Clear winner |
| D | Service | First answer by group, support group, trigram, then DB type | A row came back |
| Default set | Service + group + offering + environment | Only when both service and group are empty | Always sets all four |
| E | Service | QA Platforms | Service still empty |
| Group fallback | Group | Service's group, service's support group, record's support group, default group | Found |
| Offering | Offering | Service offering for this environment, first offering, group's offering, default offering | Found |

**What it passes on:**

| Field | What is inside | Who uses it |
|---|---|---|
| `snow_required` | Final group, business service, offering, company, environment. Each has a `from` field saying which method found it. | Task 3 |
| `snow_required.default_set_used` | True when the QA Platforms default set was applied | Task 3 (assigned to) |
| `enrichment` | Same answers in the correctoutput.sh layout | Reading and debugging |
| `group_checks`, `first_answer_rows`, `candidates`, `cis` | Evidence for how the answer was chosen | Debugging |
| `steps` | Log of every SILVA call with status and match count | Debugging |

**SILVA API calls (all `GET /api/now/v2/table/<table>` with `sysparm_display_value=all`):**

| Purpose | Table | Query (`sysparm_query`) |
|---|---|---|
| Check a group name | `sys_user_group` | `name=<group>^active=true` |
| Service by name | `cmdb_ci_service` | `name=<service>` |
| Service by sys_id | `cmdb_ci_service` | `sys_id=<id>` |
| Host record | `cmdb_ci` | `name=<host>^ORfqdn=<host>` plus each domain suffix |
| Host record (loose) | `cmdb_ci` | `nameSTARTSWITH<short>.^ORfqdnSTARTSWITH<short>.` |
| DB or entity record | `cmdb_ci` | `name=<entity>`, then `nameLIKE<entity>` |
| Record to service link | `svc_ci_assoc` | `ci_id=<record sys_id>` |
| Record to service relationship | `cmdb_rel_ci` | `child=<record sys_id>` |
| Search 1 | `cmdb_ci_service` | `assignment_group=<group id>^ORsupport_group=<group id>` |
| Search 2 | `cmdb_ci_service` | `nameLIKE<dbType>^nameLIKE<envTag>` |
| Search 3 | `cmdb_ci_service` | `nameLIKE<dbType>^nameLIKE<regionPrefix>` |
| Search 4 | `cmdb_ci_service` | `nameLIKE<trigram>` |
| Search 5 | `cmdb_ci_service_technical` | `nameLIKE<dbType>^nameLIKE<envTag>` |
| First answer by group | `cmdb_ci_service` | `assignment_group.nameLIKE<group>` |
| First answer by support group | `cmdb_ci_service` | `support_group.nameLIKE<group>` |
| First answer by trigram | `cmdb_ci_service` | `nameLIKE<trigram>` |
| First answer by DB type | `cmdb_ci_service` | `nameLIKE<dbType>` |
| Offerings of the service | `service_offering` | `parent=<service sys_id>` |
| Offering by group | `service_offering` | `assignment_group.nameLIKE<group>`, then `support_group.nameLIKE<group>` |
| Default offering | `service_offering` | `parent.name=QA Platforms^nameSTARTSWITHQA Platforms - AXA GROUP OPERATIONS` |

Each call is only made when the earlier method did not already find the answer, so a normal run makes far fewer calls than this list.

### 3d. Task 3 — `display-result`

No API calls. It turns task 1 and task 2 output into ready-to-send payloads and a yes/no decision.

| Step | What happens |
|---|---|
| Skip check | `skip` is true when maintenance is on and `SKIP_WHEN_MAINTENANCE` is true |
| Short description | `[DYNATRACE JAPAN]` + host record name (or host) + event name, max 160 characters |
| Additional Information | Text block in the INC30340215 layout |
| SNOW body | Caller, on behalf of, contact type, company, category, subcategory, impact, urgency, group, service, offering, environment, short description, description, `correlation_id` |
| Form check | One row per form field. Empty required fields go to `missing`. |
| PagerDuty body | `event_action: trigger`, `dedup_key`, summary, severity, source, links. Routing key is a placeholder. |
| Decision | `create_incident` is true when nothing is missing and `skip` is false |

**What it passes on:**

| Field | Who uses it |
|---|---|
| `snow_incident` (the body) | Task 4 |
| `pagerduty` (the body) | Task 5 |
| `decision.create_incident` and `decision.reason` | Tasks 4 and 5 |
| `form_check`, `missing` | You, when reading the run |

### 3e. Task 4 — `post-silva-incident`

| Step | What happens |
|---|---|
| Guard | Returns `skipped` if the decision is no, or on the sample event (unless `ALLOW_SAMPLE_POST`) |
| Duplicate check | Looks for an active incident with the same `correlation_id`. If found, returns `exists`. |
| Dry run | With `DRY_RUN` true, logs the body and stops |
| Create | POSTs the body. A non-2xx response fails the task. |
| Return | `created` with number, sys_id, group, service, offering, link |

**API calls:**

| Method | URL | Purpose |
|---|---|---|
| GET | `/api/now/v2/table/incident?sysparm_query=correlation_id=<display_id>^active=true` | Avoid a second ticket for the same problem |
| POST | `/api/now/v2/table/incident?sysparm_display_value=true&sysparm_exclude_reference_link=true` | Create the incident |

**Passes on:** `action` (`skipped`, `exists`, `dry_run`, `created`), `number`, `sys_id`, `url` → task 5.

### 3f. Task 5 — `trigger-pagerduty`

| Step | What happens |
|---|---|
| Guard | Skips if task 4 skipped, or if task 4 found an existing incident and `SEND_WHEN_INCIDENT_EXISTS` is false |
| Fill | Adds the routing key, the SILVA incident number and link, and a link button |
| Dry run | Logs the body with the key hidden |
| Send | POSTs to PagerDuty. A non-2xx response fails the task. |
| Return | `triggered`, PagerDuty status, `dedup_key` |

**API call:**

| Method | URL | Body highlights |
|---|---|---|
| POST | `https://events.pagerduty.com/v2/enqueue` | `routing_key`, `event_action: "trigger"`, `dedup_key: dt-problem-<display_id>`, `payload.summary`, `payload.severity`, `links` |

---

## 7. CLOSE Workflow — Resolve Both Sides

### 7a. Task Overview

| Step | Task ID | Its job | Runs after | Calls an API? |
|---|---|---|---|---|
| 1 | `prepare-close` | Rebuild the two keys and write close notes | Nothing (first) | Dynatrace Problems API (optional) |
| 2 | `resolve-silva-incident` | Find the open incident and resolve it | Task 1 OK | SILVA GET, then PATCH |
| 3 | `resolve-pagerduty` | Resolve the PagerDuty incident | Task 1 OK (parallel with task 2) | PagerDuty POST |

### 7b. Task 1 — `prepare-close`

| Step | What happens |
|---|---|
| Event | Reads the close event, or the closed sample event on manual Run |
| Keys | `correlationId = display_id`, `dedupKey = dt-problem-<display_id>` |
| Times | Start, end (now if missing), duration like "25 min" |
| Notes | `closeNotes` (short) and `workNotes` (detailed: host, entity, group tag, duration, link) |

**Passes on:** `correlationId`, `dedupKey`, `closeNotes`, `workNotes`, `usedSample`, entity, host, duration → tasks 2 and 3.

### 7c. Task 2 — `resolve-silva-incident`

| Step | What happens |
|---|---|
| Guard | Sample event returns `skipped` unless `ALLOW_SAMPLE_SEND` |
| Find open | GET the newest active incident with this `correlation_id` |
| None open | GET any incident with this key. Found → `already_resolved`. Not found → `not_found`. |
| Body | `state: "6"`, `close_code: "Solved (Permanently)"`, `close_notes`, `comments`, `work_notes`, plus `EXTRA_RESOLVE_FIELDS` |
| Update | PATCH the incident by sys_id. Errors fail the task. |

**API calls:**

| Method | URL | Purpose |
|---|---|---|
| GET | `/api/now/v2/table/incident?sysparm_query=correlation_id=<id>^active=true^ORDERBYDESCsys_created_on` | Find the open ticket |
| GET | `/api/now/v2/table/incident?sysparm_query=correlation_id=<id>^ORDERBYDESCsys_created_on` | Check if it was already closed |
| PATCH | `/api/now/v2/table/incident/<sys_id>?sysparm_display_value=true` | Resolve it |

### 7d. Task 3 — `resolve-pagerduty`

| Method | URL | Body highlights |
|---|---|---|
| POST | `https://events.pagerduty.com/v2/enqueue` | `routing_key`, `event_action: "resolve"`, `dedup_key: dt-problem-<display_id>` |

PagerDuty closes the incident that has the same `dedup_key`. If none is open, PagerDuty still accepts the event and nothing changes.

### 7e. Key Concepts

| Concept | What it means | Why you care |
|---|---|---|
| `correlation_id` | A SILVA incident field we fill with the Dynatrace `display_id` | CLOSE uses it to find the ticket OPEN created |
| `dedup_key` | PagerDuty's grouping key | Same key means trigger and resolve hit the same PD incident |
| Routing key | PagerDuty service integration key | Decides which PD service and escalation policy get paged |
| `sysparm_display_value=all` | SILVA returns both stored value and display name | Lets the script read sys_ids and human names from one call |
| `DRY_RUN` | Log the body, do not send | Safe testing on real events |
| `usedSample` | Run started by hand, not by a real event | Blocks sending test tickets by accident |

---

## 9. Common Issues and Solutions

### OPEN

| Symptom | Root cause | Solution |
|---|---|---|
| Task 4 says `skipped`, reason maintenance | Event has `AGO_Maintenance: True` | Expected. Set `SKIP_WHEN_MAINTENANCE` false only for testing. |
| Task 4 says `skipped`, fields missing | Form check found empty required fields | Read `form_check` in task 3 and fix the mapping or default |
| Task 1 shows `problemApi.error` | Missing scope `environment-api:problems:read` | Grant the scope, or ignore (it is optional) |
| Task 2 `steps` show status 401 | Wrong SILVA user or password | Fix line 318 |
| Task 2 `steps` show fetch error | `silvastg.service-now.com` not allowlisted | Add it under Settings, External requests |
| Service is QA Platforms unexpectedly | Methods A to D found nothing | Add the service to `SERVICE_MAP` or add a service tag |
| Task 5 fails with 400 | Bad routing key or payload | Check line 976 and the `payload.severity` value |
| Task 5 fails to connect | `events.pagerduty.com` not allowlisted | Add it to External requests |

### CLOSE

| Symptom | Root cause | Solution |
|---|---|---|
| `not_found` | OPEN never created a ticket (skipped or dry run) | Expected. Check the OPEN run for the same problem. |
| `already_resolved` | Someone closed it by hand first | Expected. Nothing to do. |
| PATCH returns 403 | User cannot write `state` or `close_code` | Ask the SILVA admin for the incident write role |
| PATCH returns 400 or the state does not change | Wrong choice value for state or close code | GET INC30340215 and copy the real values into lines 212–213 |

---

## 10. Responsibility Matrix

| Capability | Dynatrace workflow | SILVA | PagerDuty |
|---|---|---|---|
| Detect the problem | Yes, the Davis trigger | No | No |
| Decide group and service | Yes, task 2 asks SILVA | Yes, holds the data | No |
| Store the ticket | No | Yes, the incident table | No |
| Page on-call | No | No | Yes, escalation policy |
| Link OPEN and CLOSE | Yes, builds both keys | Stores `correlation_id` | Stores `dedup_key` |
| Resolve on close | Yes, CLOSE workflow | Yes, state 6 | Yes, resolve event |

---

## Related Files

| File | What it is |
|---|---|
| `../9-v6-full-open-silva-pagerduty/9-v6-full-open-silva-pagerduty.workflow.yaml` | OPEN v6 workflow |
| `../11-v6-close-silva-pagerduty/11-v6-close-silva-pagerduty.workflow.yaml` | CLOSE v6 workflow |
| `../10-v6-entire-logic-flow-explained/` | Detailed logic walkthrough |
| `../12-open-close-yaml-line-by-line/` | Line-by-line explanation |
| `13.sh` | Commands to view the API calls in each file and test SILVA and PagerDuty by hand |

## Commands

All commands are in [`13.sh`](13.sh). Nothing was run for you. The examples use `<password>` and `<ROUTING_KEY>` placeholders.

```bash
grep -nE "getProblem|getRows\(|fetch\(|getJson\(" ".../9-v6-full-open-silva-pagerduty.workflow.yaml"
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci_service" --data-urlencode "sysparm_query=assignment_group.nameLIKEDatabase_AXAJP" --data-urlencode "sysparm_fields=sys_id,name" --data-urlencode "sysparm_limit=5"
```

Reminder: both YAML files contain the SILVA password and PagerDuty routing key. Keep them out of any git repo.
