# Enriched Incident Post To SILVA

```
Dynatrace problem opens
  → enrich-problem   (Problems API + DQL)
       root cause, host, impacted entities, evidence
       tags: app, env, owner, snow-group, runbook
       top error logs (30 min), deployments (2 h)
       impact + urgency from impact level, severity, env
  → cmdb-lookup      (SNOW cmdb_ci by host name)
       not found     → continue without cmdb_ci
       retired (7)   → SKIP (same rule as SILVA) → no INC, no page
       found         → cmdb_ci sys_id, support group, business service
  → post-silva-enriched-incident
       rich short_description, description, work_notes, CI, group
  → trigger-pagerduty
       summary starts with INC number, links to Dynatrace + SNOW + runbook

INC looks thin?
  owner / runbook empty → tags missing on the entity
  cmdb_ci empty         → host name differs from CMDB name (check fqdn)
  u_ fields empty       → field does not exist in SILVA (SNOW ignores unknown fields)
  logs "none found"     → logs not linked to entity (dt.source_entity) or wrong loglevel
```

## Short takeaway

| Question | Answer |
| --- | --- |
| What "enrich" means | Add the facts on-call needs so they don't have to go digging |
| Where the facts come from | Dynatrace Problems API, entity tags, DQL logs and events, SNOW CMDB |
| Where they go in SNOW | `short_description`, `description`, `work_notes`, `cmdb_ci`, `assignment_group`, `business_service`, custom `u_` fields |
| Secrets | Credential vault, not in the YAML |
| Workflow file | `6-enriched-inc-post-to-silva.workflow.yaml` |
| Example payload | `6-enriched-inc-post-to-silva-sample-payload.json` |

## Summary

A plain ticket says "Problem P-123 on host X". An enriched ticket says what broke, where, who owns it, how bad it is, what the logs say, whether there was a deploy just before, and where the runbook is. The workflow collects all of that in Dynatrace, checks the CMDB the same way SILVA does, and posts one rich incident. PagerDuty then pages with the INC number and the same facts.

## Investigation

Started from the OPEN workflow in `2026-09-24/1-silva-http-snow-pd-sync-workflows/` (plain POST with title, host, correlation_id). Added four enrichment sources and a CMDB pre-check. Kept sync keys the same so the existing CLOSE workflow still works.

## Result

Import the YAML, fill in the two credential IDs, confirm the `u_` field names with SILVA owners, tag your entities, and test in STG.

---

## 1) Plain vs enriched ticket

| Field | Plain | Enriched |
| --- | --- | --- |
| Title | `[Dynatrace] Problem P-123` | `[Dynatrace][prod] Response time degradation on checkout-api` |
| Description | Problem id and link | Root cause, host, app, env, owner, zones, impacted entities, evidence, runbook |
| Work notes | Sync keys | Top 3 error log lines with counts, recent deployments, sync keys |
| CI | Empty | Linked `cmdb_ci` from CMDB |
| Team | Empty or default | `assignment_group` from CI support group or `snow-group` tag |
| Service | Empty | `business_service` from CMDB |
| Priority | Fixed 2/2 | Impact from impact level and env; urgency from severity |

---

## 2) Example: what SILVA receives

See `6-enriched-inc-post-to-silva-sample-payload.json`.

```json
{
  "short_description": "[Dynatrace][prod] Response time degradation on checkout-api",
  "description": "Dynatrace problem: P-2609271234 (PERFORMANCE, impact level SERVICES)\nStarted: 2026-09-27T12:41:07.000Z\nLink: https://abc12345.apps.dynatrace.com/ui/apps/dynatrace.davis.problems/problem/...\n\nRoot cause: checkout-api\nHost: ip-10-20-3-41...\nApp: checkout   Env: prod   Owner: payments-sre\n...\nRunbook: https://confluence.example.com/runbooks/checkout-latency",
  "work_notes": "Top error logs (last 30 min):\n[412x] HikariPool-1 - Connection is not available...\n[97x] Timeout calling payment-gateway after 5000ms\n\nDeployments (last 2 h):\n2026-09-27T12:30:02Z Deploy checkout-api v2.3.1\n\nSync: correlation_id=P-2609271234  PD dedup_key=dt-problem-P-2609271234",
  "correlation_id": "P-2609271234",
  "correlation_display": "Dynatrace",
  "contact_type": "monitoring",
  "category": "Software",
  "subcategory": "Performance",
  "impact": "2",
  "urgency": "2",
  "caller_id": "Tech_DynatraceJP_WS",
  "cmdb_ci": "a1b2c3d4e5f60718293a4b5c6d7e8f90",
  "business_service": "0f9e8d7c6b5a49382716a5b4c3d2e1f0",
  "assignment_group": "5e4d3c2b1a0f9e8d7c6b5a4938271605",
  "u_host": "ip-10-20-3-41.ap-northeast-1.compute.internal",
  "u_dynatrace_problem_url": "https://abc12345.apps.dynatrace.com/ui/apps/...",
  "u_environment": "prod",
  "u_application": "checkout"
}
```

On-call opens this ticket and immediately sees: connection pool exhausted, a deploy 11 minutes before, owner payments-sre, runbook link. That is the point of enrichment.

---

## 3) Where each field comes from

| SNOW field | Source | How |
| --- | --- | --- |
| `short_description` | Problem title, env tag, root cause name | Built string, max 160 chars |
| `description` | Problems API | `rootCauseEntity`, `impactedEntities`, `evidenceDetails`, `managementZones`, `startTime` |
| `work_notes` | DQL `fetch logs` and `fetch events` | Top 3 error messages, deployments in last 2 hours |
| `correlation_id` | Problem display id | Same sync key as before |
| `impact` | `impactLevel` plus `env` tag | APPLICATION is 1, SERVICES is 2, INFRASTRUCTURE is 2 in prod else 3 |
| `urgency` | `severityLevel` plus `env` tag | AVAILABILITY is 1, ERROR or PERFORMANCE is 2, else 3; non-prod always 3 |
| `cmdb_ci` | SNOW `cmdb_ci` lookup | By host name or fqdn |
| `assignment_group` | CI `support_group`, fallback `snow-group` tag | CMDB wins if present |
| `business_service` | CI `u_business_service` | Confirm field name with CMDB owners |
| `u_host`, `u_environment`, `u_application`, `u_dynatrace_problem_url` | Enrichment | Custom fields; must exist in SILVA |
| `contact_type` | Fixed `monitoring` | Shows it was auto-created |
| `category`, `subcategory` | Severity | Outage for AVAILABILITY, else Performance |

### Priority result with the default matrix

| Case | impact | urgency | Priority |
| --- | --- | --- | --- |
| Prod app outage (APPLICATION, AVAILABILITY) | 1 | 1 | P1 |
| Prod service errors (SERVICES, ERROR) | 2 | 2 | P3 |
| Prod service slowdown (SERVICES, PERFORMANCE) | 2 | 2 | P3 |
| Prod host CPU (INFRASTRUCTURE, RESOURCE) | 2 | 3 | P4 |
| STG anything | 3 | 3 | P5 (or P4) |

Tune these rules with your team; they are a starting point.

---

## 4) The workflow tasks

| Task | What it does | Fails when |
| --- | --- | --- |
| `enrich-problem` | Calls Problems API and runs 2 or 3 DQL queries | Missing permissions for problems, logs, events, entities |
| `cmdb-lookup` | GET `cmdb_ci` by host; returns `skip:true` if retired | Allowlist or credentials wrong |
| `post-silva-enriched-incident` | POST enriched body; runs only if `skip == false` | SILVA rejects body; 401 or 403 |
| `trigger-pagerduty` | Pages with INC number and links | Routing key wrong; allowlist |

Key code pieces:

```javascript
// tags → owner, runbook, snow-group
const owner = tagValue(prob.entityTags, 'owner');
const runbook = tagValue(prob.entityTags, 'runbook');

// top error logs for the root cause entity
fetch logs, from:now()-30m
| filter dt.source_entity == "<rootId>" or host.name == "<host>"
| filter loglevel == "ERROR" or loglevel == "SEVERE"
| summarize count = count(), by:{content}
| sort count desc
| limit 3

// retired CI → skip, same as SILVA
const retired = String(row.install_status) === '7';
```

```yaml
conditions:
  states:
    cmdb-lookup: OK
  custom: '{{ result("cmdb-lookup").skip == false }}'
  else: SKIP
```

---

## 5) Enrichment rules of thumb

| Rule | Why |
| --- | --- |
| Put the most useful fact in the title | Many people only read the title in lists and PagerDuty |
| Keep `description` for static facts and `work_notes` for evidence | Description stays clean; notes are time-stamped |
| Limit logs to top 3 with counts | Enough signal; avoids huge tickets |
| Cut long text (description 3900 chars) | SNOW string fields have size limits |
| Never put secrets or personal data in tickets | Tickets are widely readable; log lines may contain PII, so review filters |
| Send sys_ids when you have them | Display names can be duplicated; sys_id is exact |
| Use `sysparm_input_display_value=true` for fallback names | Lets `snow-group` tag send a group name |
| Keep sync keys unchanged | CLOSE workflow keeps working |

---

## 6) What you must set up

| Item | Where | Why |
| --- | --- | --- |
| External requests allowlist | Dynatrace settings | `silvastg.service-now.com`, `events.pagerduty.com` |
| Credential vault entry for SNOW | Dynatrace credential vault (Username/Password) | Replace `__SNOW_CREDENTIAL_ID__` |
| Credential vault entry for PagerDuty | Dynatrace credential vault (Token) | Replace `__PD_CREDENTIAL_ID__` |
| Workflow actor permissions | Workflow settings | Read problems, logs, events, entities, credentials |
| Entity tags | Dynatrace auto-tagging rules | `app`, `env`, `owner`, `snow-group`, `runbook` |
| SILVA field list | SILVA / SNOW owners | Confirm `u_` names and required fields |
| SNOW role for CMDB read | SNOW admin | `cmdb_ci` GET needs read access |

---

## 7) Common problems

| Symptom | Cause | Fix |
| --- | --- | --- |
| `enrich-problem` 403 | Workflow actor lacks scopes | Grant problems, storage logs, events, entities read |
| Owner and runbook empty | Tags not on the entity | Add auto-tagging rules |
| `cmdb_ci` empty | Host name mismatch | Try fqdn or short name; align CMDB naming |
| INC created but `u_` fields blank | Fields do not exist in SILVA | Ask SILVA owners; rename fields |
| No INC and no page | CI retired, so skipped | Expected; check CMDB status if wrong |
| Duplicate INC | Classic ITSM toggle still on | Turn it off |
| Description cut off | Over 3900 chars | Expected; full detail stays in Dynatrace link |

---

## Data flow map

```
Dynatrace Problem (ACTIVE, CREATED/REOPENED)
  │
  ▼
enrich-problem
  ├─ Problems API  → root cause, impacted, evidence, zones, tags
  ├─ DQL logs      → top 3 errors (30 min)
  ├─ DQL events    → deployments (2 h)
  └─ rules         → impact, urgency
  │
  ▼
cmdb-lookup ──GET──► SNOW cmdb_ci (by host)
  │   retired → SKIP (stop)
  ▼
post-silva-enriched-incident ──POST──► SILVA / SNOW incident
  │   returns INC number + sys_id
  ▼
trigger-pagerduty ──POST──► PagerDuty (summary = INC + title, links, custom_details)

Close: existing CLOSE workflow (same correlation_id + dedup_key)
```

## Related files

| File | Role |
| --- | --- |
| `6-enriched-inc-post-to-silva.workflow.yaml` | Full workflow to import |
| `6-enriched-inc-post-to-silva-sample-payload.json` | Example body SILVA receives |
| `2026-09-24/1-silva-http-snow-pd-sync-workflows/2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE still works unchanged |
| `2026-09-27/3-snow-apis-in-detail/` | Table API reference |
| `6.sh` | Test POST and field checks (you run) |

## Commands

See `6.sh`. Test in STG only.
