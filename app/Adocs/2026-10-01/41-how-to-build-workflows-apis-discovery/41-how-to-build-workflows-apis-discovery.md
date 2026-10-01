# How To Build The Workflows

## Decision tree

```
Goal: Dynatrace problem → SILVA incident + PagerDuty alert, and close both later
 Step 1  What does Dynatrace give me?        → look at a real problem event + Problems API (41.sh 1-3)
 Step 2  What does a good ticket look like?  → open a human / known-good SILVA incident (41.sh 4)
 Step 3  What are the real field keys?       → sys_dictionary or "Show XML" on the form (41.sh 5)
          label ≠ key? (Business service = u_business_service, Service Offering = cmdb_ci)
 Step 4  How do I get each sys_id?           → GET the table with sysparm_display_value=all (41.sh 6-9)
 Step 5  How do records link?                → cmdb_ci → svc_ci_assoc / cmdb_rel_ci → service → service_offering (41.sh 10-13)
          no link?                           → incident history on the host CI (41.sh 14)
 Step 6  What values are allowed?            → sys_choice for state, close_code, impact... (41.sh 15-16)
 Step 7  Can I page?                         → PagerDuty Events v2 test trigger + resolve (41.sh 17-18)
 Step 8  Build in layers                     → extract → resolve → build → preview → send
 Step 9  Test safely                         → sample event, DRY_RUN, previews, ALLOW_SAMPLE_POST
 Step 10 Go live                             → allowlist hosts, Save / Deploy, one OPEN + one CLOSE
 Something fails?                            → see "Errors we hit and why" table
```

## Short takeaway

| Question | Answer |
|---|---|
| What is the core idea? | Read the problem, look up the right SILVA records, build the bodies, preview, then send. |
| What is the hardest part? | Finding the right SILVA field keys and sys_ids. Labels on the form are not the API keys. |
| How do you find field keys? | Copy them from a known-good incident (INC30340215) and confirm in `sys_dictionary`. |
| How do you find sys_ids? | GET the table with `sysparm_display_value=all`, which returns both the id and the name. |
| How do you test without damage? | Sample event, `DRY_RUN`, preview tasks, and `ALLOW_SAMPLE_POST = false`. |
| What links OPEN and CLOSE? | `correlation_id` in SILVA and `dedup_key` in PagerDuty, both from the problem display id. |

## Summary

Building this is mostly detective work, not coding. You first look at real data on both sides (a Dynatrace problem and a good SILVA ticket), map each SILVA field to where its value can come from, and only then write the JavaScript. Each workflow task does one job so you can see exactly where a value came from and which step failed.

---

## Part 1: The building blocks

### Dynatrace Workflows

| Concept | What it means | Why you care |
|---|---|---|
| Workflow | A graph of tasks that Dynatrace runs on a trigger. | This is the "program". |
| Trigger | What starts it. Here: Davis problem created, or closed. | OPEN and CLOSE differ only by trigger and tasks. |
| Task | One step. Here every task is `run-javascript`. | You write plain JavaScript per task. |
| Predecessors | Tasks that must finish first. | Builds the arrows in the graph. |
| Conditions | `states: { task: OK }` = only run if that task succeeded. | Stops later tasks after a failure. |
| Position | `x`, `y` on the canvas. | Layout only; x=0 left column, x=1 right column. |
| `ex.event()` | The event that triggered the run. Empty on manual Run. | Source of display_id, tags, entity names. |
| `ex.result("task")` | Output of an earlier task. | How tasks pass data. |
| External requests allowlist | Settings list of hosts JavaScript may call. | Without it, `fetch` to SILVA or PagerDuty is blocked. |
| Draft | Saved but not deployed. Trigger does not fire. | Must Save / Deploy to go live. |

### The JavaScript task skeleton

```js
import { execution } from '@dynatrace-sdk/automation-utils';

export default async function ({ executionId }) {
  const ex = await execution(executionId);
  const ev = ex.event() || {};                       // trigger event
  const prev = await ex.result("previous-task");     // earlier task output
  const res = await fetch("https://host/api", { method: "GET", headers: {} });
  return { anything: "you return becomes this task's result" };
}
```

### Dynatrace SDK modules used

| Module | Function | Used for |
|---|---|---|
| `@dynatrace-sdk/automation-utils` | `execution(id)`, `ex.event()`, `ex.result()` | Read trigger event and earlier results |
| `@dynatrace-sdk/client-classic-environment-v2` | `problemsClient.getProblem({ problemId })` | Full problem: tags, root cause, evidence, times |
| `@dynatrace-sdk/app-environment` | `getEnvironmentUrl()` | Build the problem link |

---

## Part 2: Every API used

### Dynatrace

| API | Method and path | Task | What we get |
|---|---|---|---|
| Problems API v2 (SDK) | `problemsClient.getProblem(event.id)` | extract-event-tags, prepare-close | Entity tags, root cause entity, evidence, start and end time |
| Trigger event | `ex.event()` | first task | display_id, event.id, entity names, tags, maintenance flag |

### SILVA (ServiceNow Table API, `https://silvastg.service-now.com`)

All calls use Basic auth (user `Tech_DynatraceJP_WS`). Production SILVA rejects this account, so use stg only.

| Table | Method | Task | Why |
|---|---|---|---|
| `sys_user_group` | GET | resolve-snow-values | Check the tag group exists and is active; get its sys_id |
| `cmdb_ci` | GET | resolve-snow-values | Find the host CI by name or FQDN |
| `svc_ci_assoc` | GET | resolve-snow-values | Services the CI belongs to |
| `cmdb_rel_ci` | GET | resolve-snow-values | Relationships like "Depends on::Used by" from CI to service |
| `cmdb_ci_service` | GET | resolve-snow-values | Business service search (exclude `sys_class_name=service_offering`) |
| `service_offering` | GET | resolve-snow-values | Offerings of a service (`parent=<service sys_id>`) |
| `incident` (history) | GET | resolve-snow-values | Offering humans used on past incidents of this host |
| `incident` (duplicate) | GET | preview and post | `correlation_id=<id>^active=true` |
| `incident` | POST | post-silva-incident | Create the ticket |
| `incident/<sys_id>` | PATCH | resolve-silva-incident | Resolve the ticket |
| `sys_choice` | GET | find-silva-incident | Allowed values for state and close_code |
| Stats API `/api/now/stats/incident` | GET | manual checks only | Count incidents grouped by a field |

Common query parameters:

| Parameter | What it does |
|---|---|
| `sysparm_query` | Filter. `^` = AND, `^OR` = OR, `LIKE`, `STARTSWITH`, `ISNOTEMPTY`, `ORDERBYDESC<field>`. |
| `sysparm_fields` | Only return these fields (faster, clearer). |
| `sysparm_display_value=all` | Return both `value` (sys_id) and `display_value` (name) for each field. |
| `sysparm_exclude_reference_link=true` | Drop the extra link objects. |
| `sysparm_limit` | Max rows. |

### PagerDuty

| API | Method and path | Task | Body |
|---|---|---|---|
| Events API v2 | POST `https://events.pagerduty.com/v2/enqueue` | trigger-pagerduty | `routing_key`, `event_action: trigger`, `dedup_key`, `payload { summary, source, severity, ... }` |
| Events API v2 | POST same | resolve-pagerduty | `routing_key`, `event_action: resolve`, `dedup_key` |

The routing key comes from the PagerDuty service: Integrations, then "Events API v2". No user token is needed.

---

## Part 3: How we figured out each piece

### Step 1: See what Dynatrace gives you

| Action | How | What you learn |
|---|---|---|
| Look at a real problem event | Run the workflow on a real problem, open task 1 result `event_properties`. | Exact event keys: `display_id`, `event.id`, `entity_tags`, `affected_entity_names`, `dt.security_context`. |
| Query problems with DQL | `fetch dt.davis.problems \| filter display_id == "P-261090"` in a Notebook | Same fields without running the workflow. |
| Call the Problems API | `41.sh` line 2 (API token with `problems.read`) | Tags with key and value, root cause, evidence. |

### Step 2: Look at a known-good ticket

| Action | How | What you learn |
|---|---|---|
| Find a ticket a person or system made correctly | INC30340215 (created by the system, Resolved). | Which fields are filled and with which values. |
| Read it by API | `41.sh` line 4 with `sysparm_display_value=all` | Each field's sys_id and name together. |

### Step 3: Find the real field keys (label is not the key)

| Form label | Real API key | How we found it |
|---|---|---|
| Business service | `u_business_service` | `business_service` is labelled "ZZZ-Do-not-use" in sys_dictionary. |
| Service Offering | `cmdb_ci` | sys_dictionary column_label for `cmdb_ci` on incident. |
| Configuration item | `u_configuration_item` | Same; it is a custom field holding the host CI. |
| On Behalf Of | `u_on_behalf_of` | Same. |
| Environment | `u_environment` | Same. |
| Correlation ID | `correlation_id` | Standard field. |

Three ways to find a key:

| Method | Steps |
|---|---|
| sys_dictionary query | `41.sh` line 5 lists `element` (key) and `column_label` (label). |
| Form right-click | Right-click the field label on the form, "Show - '<field>'" shows the key. |
| XML view | Open `incident.do?XML&sys_id=<sys_id>` to see every key and raw value. |

### Step 4: Get each sys_id

| Value | Table | Query |
|---|---|---|
| Caller (Dynatrace JP) | `sys_user` | Copy from INC30340215 `caller_id.value`. |
| Assignment group | `sys_user_group` | `name=<group name>^active=true` |
| Business service | `cmdb_ci_service` | `name=<name>^sys_class_name!=service_offering` |
| Offering | `service_offering` | `parent=<service sys_id>` |
| Host CI | `cmdb_ci` | `name=<host>^ORfqdn=<host.domain>` |
| Company | `core_company` | Usually from the service or CI `company` field. |

Rule we learned: reference fields (caller, company, group, service, offering, CI) must be a 32-character sys_id in the POST body. A name may be silently ignored.

### Step 5: Work out how records link

```
host CI (cmdb_ci, ts12)
   ├─ svc_ci_assoc.ci_id        → service_id
   ├─ cmdb_rel_ci.child         → parent (a service, e.g. "Depends on::Used by")
   └─ incident.u_configuration_item (history) → cmdb_ci (offering) → parent (business service)
business service (cmdb_ci_service)
   └─ service_offering.parent   → offerings, one per environment (u_environment)
```

| Discovery | What happened | What we built |
|---|---|---|
| `service_offering` is a child class of `cmdb_ci_service` | Business service searches returned offerings too. | Always add `^sys_class_name!=service_offering`. |
| A CI can link to several services | First service had no offering. | Switch to the next CI service with offerings. |
| Some hosts link only to a technical service | ts12 → "Technology Management Service", no offering. | Incident history fallback: use the offering people chose before. |
| Offerings are per environment | Same service has Production, Development... offerings. | Pick the offering whose `u_environment` matches the event. |

### Step 6: Find allowed values

| Field | Table | Why |
|---|---|---|
| `state` | `sys_choice` (`element=state`) | Resolved is a number (usually 6). |
| `close_code` | `sys_choice` (`element=close_code`) | Must match exactly. |
| `impact`, `urgency` | `sys_choice` | 1 to 4. |
| `u_environment` | `sys_choice` | Exact labels like "Integration / Test". |
| `category`, `subcategory` | `sys_choice` | Value like "other". |

### Step 7: Prove PagerDuty works

| Action | How |
|---|---|
| Test trigger | `41.sh` line 17. Response `status: success`. Alert appears in PagerDuty. |
| Test resolve | `41.sh` line 18 with the same dedup_key. Alert resolves. |

### Step 8: Build in layers

| Layer | Task | Rule |
|---|---|---|
| Read | extract-event-tags | Only Dynatrace data. No SILVA. |
| Look up | resolve-snow-values | Only GET. Record every query in `steps` for debugging. |
| Build | build-payload | No network. Pure mapping and decision. |
| Check | preview tasks | GET only. Mark OK, MISSING, WRONG. |
| Send | post / trigger / resolve | Gates first, then DRY_RUN, then send. |

Why layers: when a ticket is wrong you open one task result and see exactly which lookup or rule caused it.

### Step 9: Test safely

| Tool | How it protects you |
|---|---|
| Sample event | Manual Run uses fake data; send tasks skip it unless `ALLOW_SAMPLE_POST = true`. |
| `DRY_RUN = true` | Send tasks return the body instead of sending. |
| Preview tasks | Show exactly what would be sent and why it would skip. |
| Duplicate check | OPEN never creates a second open incident for the same problem. |
| Stg only | All SILVA calls go to silvastg. |

### Step 10: Go live

| Step | Action |
|---|---|
| 1 | Settings, External requests: allow `silvastg.service-now.com` and `events.pagerduty.com`. |
| 2 | Import OPEN (seq 36) and one CLOSE (seq 37 or 39). |
| 3 | Run each once (sample) and read the previews. |
| 4 | Save / Deploy both. |
| 5 | Disable old PREVIEW, TEST and earlier OPEN versions so one problem is handled once. |

---

## Part 4: Errors we hit and why

| Symptom | Cause | Fix |
|---|---|---|
| `fetch` fails or is blocked | Host not in the external requests allowlist | Add the host in Settings. |
| HTTP 401 from SILVA | Wrong user or password | Check credentials. |
| Production SILVA rejects the account | Account only exists on stg | Use silvastg. |
| Business service field empty on the ticket | Sent `business_service` (ZZZ-Do-not-use) | Use `u_business_service`. |
| Service Offering empty | Host only linked to a technical service | Incident history fallback. |
| Service search returns offerings | `service_offering` extends `cmdb_ci_service` | Add `^sys_class_name!=service_offering`. |
| Tag group not matched | Tag key written with `-` (`AGO-DEFAULT-ASSIGNMENT-GROUP`) | Match both `-` and `_`. |
| Ticket skipped though all fields OK | Tag `AGO_Maintenance:True` | Expected; or set `USE_MAINTENANCE_TAG = false`. |
| Field shows the name, not the id | Read without `sysparm_display_value=all` | Use `=all` and read `.value`. |
| Workflow never runs | Still a Draft | Save / Deploy. |
| Resolve PATCH returns 200 but not Resolved | SILVA rule needs more close fields | Add them to `EXTRA_FIELDS`. |

---

## Data flow map

```
          DISCOVER (once, by hand)                          BUILD (workflow, every problem)
┌───────────────────────────────────────┐        ┌──────────────────────────────────────────────┐
│ Dynatrace event + Problems API        │──keys─►│ extract-event-tags                           │
│ Known-good INC30340215                │─fields►│ build-payload (field list, settings)         │
│ sys_dictionary / XML                  │─keys──►│ build-payload (u_business_service, cmdb_ci)  │
│ sys_user_group, cmdb_ci, service ...  │─how───►│ resolve-snow-values (lookup order)           │
│ sys_choice                            │─values►│ build-close-payload (state, close_code)      │
│ PagerDuty test trigger / resolve      │─key───►│ trigger-pagerduty / resolve-pagerduty        │
└───────────────────────────────────────┘        └──────────────────────────────────────────────┘
```

## Related files

| File | Purpose |
|---|---|
| `36-standard-flow-preview-then-post/` | OPEN workflow built with this method. |
| `37-close-workflow-preview-then-resolve/` | CLOSE with previews. |
| `39-close-direct-silva-pagerduty/` | CLOSE direct. |
| `40-open-close-workflows-end-to-end/` | Task-by-task explanation. |
| `41.sh` | Every discovery query, in step order. |

## Commands

See `41.sh`. Replace `__DT_API_TOKEN__` with a Dynatrace API token (scope `problems.read`) before lines 2 and 3. Lines 17 and 18 send a real test alert to PagerDuty; run them only when you want to test paging.
