# Enrich Existing SILVA Incident From Workflow

```
Who creates the INC?
  Our workflow can POST the full body     → use seq 6 (enrich at creation)
  SILVA creates it (gatekeeper, fixed body) → use THIS workflow (enrich after creation)

This workflow:
  Problem CREATED / UPDATED / REOPENED
    → collect-context        Problems API + tags + DQL logs + DQL deploys
    → find-silva-incident    GET incident by correlation_id
         not found yet  → throw → retry every 30 s, up to 6 times
         still missing  → SILVA skipped it (retired CI) or uses a different key
    → enrich-silva-incident  PATCH
         INC resolved/closed/canceled → do nothing
         facts unchanged (same signature) → no new work note
         changed → add [DT-ENRICH] work note + fill EMPTY u_ fields only
    → comment-back-dynatrace INC number + link on the Dynatrace problem (once)

Enrichment not showing?
  403 on PATCH       → SNOW user lacks write on incident / work_notes
  u_ fields blank    → field names differ in SILVA
  task keeps retrying → SILVA uses a different field than correlation_id
```

## Short takeaway

| Question | Answer |
| --- | --- |
| Problem solved | SILVA creates the INC, but it is thin; we add Dynatrace context afterwards |
| How we find the INC | `correlation_id = <Dynatrace problem id>` |
| What we add | One `[DT-ENRICH]` work note, plus empty custom fields |
| What we never overwrite | SILVA's routing: priority, assignment group, CI, state |
| Avoid spam | A signature field `u_dt_enrich_sig`; new note only when facts change |
| Two-way link | INC number posted as a comment on the Dynatrace problem |
| Workflow file | `8-enrich-existing-silva-inc.workflow.yaml` |

## Summary

In your setup SILVA is the gatekeeper and creates the incident itself, so the ticket often only has a title and a host. This workflow waits for SILVA's ticket, finds it by the problem id, and adds a clear Dynatrace summary as a work note: root cause, impacted services, evidence, top error logs, recent deploys, owner, and runbook. It fills custom fields only if they are empty, never touches SILVA's routing fields, and links the INC back into Dynatrace. When the problem updates, it adds a new note only if something actually changed.

## Investigation

Seq 6 assumed the workflow controls the POST body. The new need is enriching a ticket SILVA already created. That requires a find step (with retry, because SILVA may be slower than Dynatrace), a PATCH step that respects SILVA's fields, and a guard against duplicate notes on every UPDATED event.

## Result

Import the YAML, set the credential ID, confirm with SILVA owners: the find field (`correlation_id`), write access to `work_notes`, and the `u_` field names (including a new `u_dt_enrich_sig` string field, or remove that logic). Test in STG.

---

## 1) Before and after

| Part of the INC | Before (SILVA only) | After enrichment |
| --- | --- | --- |
| Short description | `Dynatrace alert host ip-10-20-3-41` | Unchanged (SILVA owns it) |
| Priority / group / CI | Set by SILVA | Unchanged |
| Work notes | Empty | `[DT-ENRICH]` block with full context |
| `u_host`, `u_environment`, `u_application` | Often empty | Filled if empty |
| `u_dynatrace_problem_url` | Empty | Filled |
| Dynatrace problem | No SNOW link | Comment `ServiceNow INC0098765: <link>` |

### Example work note SILVA ticket receives

```
[DT-ENRICH] CREATED from Dynatrace workflow
Problem: P-2609271234 (PERFORMANCE, impact level SERVICES) started 2026-09-27T12:41:07.000Z
Link: https://abc12345.apps.dynatrace.com/ui/apps/dynatrace.davis.problems/problem/-4711223344556677_1759000000000V2
Root cause: checkout-api
Host: ip-10-20-3-41.ap-northeast-1.compute.internal   App: checkout   Env: prod   Owner: payments-sre
Management zones: JP-Prod, Payments

Impacted entities:
- checkout-api
- /api/v1/checkout
- web-frontend

Evidence:
- Response time degradation
- Failure rate increase
- Database connection pool exhausted

Top error logs (last 30 min):
- [412x] HikariPool-1 - Connection is not available, request timed out after 30000ms
- [97x] Timeout calling payment-gateway after 5000ms
- [12x] Circuit breaker OPEN for payment-gateway

Deployments (last 2 h):
- 2026-09-27T12:30:02Z Deploy checkout-api v2.3.1

Runbook: https://confluence.example.com/runbooks/checkout-latency
```

If the problem later updates (for example, a new impacted service appears), a second `[DT-ENRICH] UPDATED` note is added. If nothing changed, no note is added.

---

## 2) The four tasks

| Task | What it does | Why it is built this way |
| --- | --- | --- |
| `collect-context` | Reads problem details, tags, top 3 error logs, deploys | Same facts as seq 6 |
| `find-silva-incident` | GET `incident?sysparm_query=correlation_id=<id>` | Throws when not found so the workflow **retries** (6 × 30 s) while SILVA catches up |
| `enrich-silva-incident` | PATCH work note and empty custom fields | Respects SILVA ownership; skips closed tickets; skips unchanged facts |
| `comment-back-dynatrace` | Adds INC link as a problem comment | Checks existing comments first so it only posts once |

### Retry block

```yaml
retry:
  count: 6
  delay: 30
  failedLoopIterationsOnly: true
```

About 3 minutes of waiting. If still no INC, the task fails. That usually means SILVA skipped it (retired CI) or stores the id in another field.

### Fields we never change

| Field | Why |
| --- | --- |
| `priority`, `impact`, `urgency` | SILVA or the SNOW team decides severity |
| `assignment_group`, `assigned_to` | SILVA routing rules |
| `cmdb_ci` | SILVA CMDB logic |
| `state` | Humans and the CLOSE workflow |
| `short_description` | SILVA's naming standard |

### Duplicate-note guard

```javascript
const sig = [rootName, impacted.join('|'), evidence.join('|'), deployVersions].join('#');
const changed = inc.current.u_dt_enrich_sig !== sig;
if (changed) { body.work_notes = note; body.u_dt_enrich_sig = sig; }
```

| Option if `u_dt_enrich_sig` cannot be added | How |
| --- | --- |
| Read the last work note | GET `sys_journal_field` where `element_id=<sys_id>` and value starts with `[DT-ENRICH]`, compare text |
| Enrich only once | Change the trigger to `CREATED` and `REOPENED` only |

---

## 3) Seq 6 vs this workflow

| Topic | Seq 6: enrich at creation | Seq 8: enrich after creation |
| --- | --- | --- |
| Who creates INC | Our workflow (POST) | SILVA |
| When to use | SILVA accepts our full body | SILVA owns creation and its body format |
| Where enrichment lands | Description and fields at creation | Work note plus empty fields |
| Handles later updates | No | Yes (UPDATED trigger, signature) |
| Links back to Dynatrace | No | Yes (problem comment) |
| Extra SNOW permission | Create incident | Read and update incident |

Both keep `correlation_id` so the CLOSE workflow still works.

---

## 4) What to confirm with SILVA owners

| Question | Why it matters |
| --- | --- |
| Which field holds the Dynatrace problem id? | The find step depends on it (`FIND_FIELD`) |
| Can `Tech_DynatraceJP_WS` PATCH incidents? | Otherwise 403 |
| Can we write `work_notes`? | Main place for enrichment |
| Exact `u_` field names | Unknown fields are silently ignored |
| Can we add `u_dt_enrich_sig` (string, 255)? | Duplicate-note guard |
| Any business rule that blocks integration updates? | Some instances lock auto-created tickets |
| Typical delay before INC exists | Tune retry count and delay |

---

## 5) Common problems

| Symptom | Cause | Fix |
| --- | --- | --- |
| `find-silva-incident` fails after retries | SILVA skipped (retired CI) or different key | Check CMDB status; confirm find field |
| PATCH 403 | No write role or ACL | Ask SNOW admin for role on incident |
| Note posted every few minutes | Signature field missing, so always "changed" | Add field or use journal check |
| `u_` fields stay blank | Wrong names, or already filled | Check `sys_dictionary`; we only fill empty ones |
| Enrichment on closed ticket | Not possible; state 6, 7, 8 are skipped | Expected |
| Problem comment missing | Workflow actor lacks problem write | Grant problem comment permission |
| Allowlist error | `silvastg.service-now.com` not allowed | Add under External requests |

---

## Data flow map

```
Dynatrace Problem (CREATED / UPDATED / REOPENED)
  │                                  SILVA (separately) creates INC0098765
  ▼                                          │
collect-context                              │
  │ problem facts, tags, logs, deploys       │
  ▼                                          ▼
find-silva-incident ──GET correlation_id──► SNOW incident
  │  not yet? throw → retry 30 s × 6
  ▼
  ├──► enrich-silva-incident ──PATCH──► work_notes [DT-ENRICH] + empty u_ fields
  │         skip if closed or unchanged
  └──► comment-back-dynatrace ──► Dynatrace problem comment "ServiceNow INC0098765: link"

Close: existing CLOSE workflow resolves by correlation_id
```

## Related files

| File | Role |
| --- | --- |
| `8-enrich-existing-silva-inc.workflow.yaml` | Workflow to import |
| `2026-09-27/6-enriched-inc-post-to-silva/` | Alternative: enrich at creation |
| `2026-09-27/7-snow-inc-ticket-example/` | What a finished ticket looks like |
| `2026-09-24/1-silva-http-snow-pd-sync-workflows/` | CLOSE workflow (unchanged) |
| `8.sh` | Manual checks (you run) |

## Commands

See `8.sh`. STG only.
