# OPEN And CLOSE Workflows End To End

## Decision tree

```
Dynatrace detects a problem (P-261090)
 └─ OPEN workflow (seq 36)
     tags read → SILVA lookups → payload built
     decision create?  NO  → maintenance on, or a required field missing → nothing sent
                       YES → preview SILVA ready? → POST incident (skip if already open)
                             preview PD ready?    → trigger PagerDuty
     Result: SILVA INC with correlation_id = P-261090, PD alert with dedup_key dt-problem-P-261090

Dynatrace problem closes
 └─ CLOSE workflow (seq 37 preview, or seq 39 direct)
     find SILVA INC by correlation_id = P-261090
       none / already resolved → SILVA skip
       open                    → check state + close_code values → PATCH to Resolved
     PagerDuty resolve with dedup_key dt-problem-P-261090 (always)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does OPEN do? | Turns a new Dynatrace problem into one SILVA incident and one PagerDuty alert. |
| What does CLOSE do? | When that problem closes, resolves the same SILVA incident and the same PagerDuty alert. |
| How do they find each other? | Two shared keys built from the problem display id. |
| SILVA key | `correlation_id` = `P-261090` |
| PagerDuty key | `dedup_key` = `dt-problem-P-261090` |
| Safety | Both have previews (CLOSE seq 39 is the direct version). Duplicate checks stop double tickets. |

## Summary

Think of it as one ticket life cycle split into two workflows. OPEN does the hard work: it figures out which group, business service, offering and host CI the incident belongs to, using tags and SILVA lookups. CLOSE is simple: it only needs the problem id to find what OPEN created and close it. Nothing else is shared between them, so CLOSE still works even if OPEN's lookup logic changes later.

---

## Part 1: The OPEN workflow (seq 36, standard flow)

### The picture

```
Problem trigger (problem created)
   ▼
1 extract-event-tags  ─► 2 resolve-snow-values ─► 3 build-payload
                                                      ├─► 4a preview-silva-incident ─► 5a post-silva-incident
                                                      └─► 4b preview-pagerduty ─────► 5b trigger-pagerduty
```

### Trigger

| Setting | Value | What it means |
|---|---|---|
| Type | davis-problem | Starts on Davis problems, not on raw logs or metrics. |
| Filter | `event.status == "ACTIVE"` and `event.status_transition == "CREATED"` | Only new problems, not updates. |
| Categories | availability, error, slowdown, resource, custom | All problem types. |
| onProblemClose | false | Closing is handled by the CLOSE workflow. |

### Task 1: extract-event-tags (read Dynatrace, no SILVA)

What goes in: the problem event Dynatrace passes to the workflow.

| Step | What it does | Example for P-261090 |
|---|---|---|
| Read event | Takes the live event. On manual Run it uses SAMPLE_EVENT. | `display_id` P-261090 |
| Problems API | `problemsClient.getProblem(event.id)` for entity tags, root cause and evidence. | Root cause ts12.hk.intraxa |
| Parse tags | Splits each `key:value` tag. Keys with `-` also match `_`. | `AGO-DEFAULT-ASSIGNMENT-GROUP` matches |
| Group candidates | In order: `AGO_AXA_SUPPORTGROUP`, other `*_ASSIGNMENT_GROUP`, then `AGO_DEFAULT_ASSIGNMENT_GROUP`. | InfraSupport_Dist-WindowsHK_L2_ASIA |
| Environment | From `AGO_AXAENVIRONMENTNAME`, `env`, namespace, security context, else default. | Development |
| App code | `dt.cost.product` or `AGO_AXAAPPCODE`, else the `[CODE.ENV]` prefix of the service name. | — |
| Host | `host` tag or host name fields. | ts12 |
| Maintenance | Dynatrace maintenance window, or tag `AGO_Maintenance:True`. | false |

What comes out: `dynatrace_alert` (what happened) and `snow_inputs` (what SILVA lookups need).

### Task 2: resolve-snow-values (SILVA GET only, never changes anything)

This answers four questions: which group, which business service, which offering, which host CI.

| Question | How it is answered (first hit wins) |
|---|---|
| Is the tag group real? | GET `sys_user_group` by name, active only. |
| Which host CI? | GET `cmdb_ci` by host name or FQDN with domains like `hk.intraxa`. |
| Which business service? | A) SERVICE_MAP or service tag. B) Services linked to the CI (`svc_ci_assoc`, `cmdb_rel_ci`). C) Scored search, score at least 5. D) First answer by app code or group. E) Default "QA Platforms". |
| Chosen service has no offering? | Switch to another CI service that has offerings. |
| Which offering? | 1) Service offering matching the environment. 2) Offering found by the search. 3) Offering most used on past incidents of this host CI (history). 4) Default offering. 5) First offering of the service. 6) First offering owned by the group. |
| Final group? | GROUP_ORDER: tag, then service assignment group, then service support group, then CI support group, then default. |
| Company? | Business service company, else CI company, else group company, else default. |

P-261090 example: ts12 is linked only to a technical service with no offering. The history step found offering `cfbf255f…` on 20 of 20 recent incidents and replaced the business service with its parent `37273dbc…`.

### Task 3: build-payload (no network)

| Part | What it builds |
|---|---|
| SILVA incident body | caller_id, u_on_behalf_of, contact_type event, company, u_environment, u_business_service, cmdb_ci (offering), u_configuration_item (host), category, subcategory, impact 4, urgency 4, assignment_group, short_description, description, correlation_id. |
| short_description | `[DYNATRACE JAPAN][<host>] - <event name>` |
| description | Event description plus an "Additional Information" block (problem link, tags, hosts, environment). |
| PagerDuty body | event_action trigger, dedup_key `dt-problem-<id>`, summary, source, severity, group, component, custom_details. |
| Decision | Create only if group, business service, offering, environment and short description are all filled, and maintenance is off. |

### Task 4a: preview-silva-incident (GET only)

| Check | What it means |
|---|---|
| Field check | Each SILVA form field: OK, MISSING (mandatory and empty), WRONG (reference field without a 32-character sys_id). |
| Duplicate check | GET incident `correlation_id=<id>^active=true`. If one exists, OPEN would skip. |
| ready | true when no MISSING or WRONG and the decision is create. |

### Task 5a: post-silva-incident (sends)

| Step | What happens |
|---|---|
| Gates | Skip if decision is skip, preview found problems, or sample event (unless ALLOW_SAMPLE_POST). |
| Duplicate GET again | If an open incident exists now, return `exists` with its number. |
| DRY_RUN | If true, return the body without sending. |
| POST | `POST /api/now/v2/table/incident` with the body. |
| Result | `action: created`, INC number, sys_id, link. |

### Task 4b and 5b: PagerDuty branch

| Task | What happens |
|---|---|
| preview-pagerduty | Checks event_action, dedup_key, summary, source, severity. Routing key hidden. |
| trigger-pagerduty | Skips if preview not ready or sample. Adds routing key and a link to the Dynatrace problem. POSTs to `events.pagerduty.com/v2/enqueue`. |

Why parallel: PagerDuty does not wait for SILVA, so on-call is paged even if SILVA is slow or fails. The link between the two is the problem id in `custom_details.snow_correlation_id`.

---

## Part 2: The CLOSE workflow (seq 37 preview, seq 39 direct)

### The picture (seq 37)

```
Problem trigger (problem closed)
   ▼
1 prepare-close ─► 2 find-silva-incident ─► 3 build-close-payload
                                               ├─► 4a preview-silva-close ──────► 5a resolve-silva-incident
                                               └─► 4b preview-pagerduty-resolve ─► 5b resolve-pagerduty
```

Seq 39 is the same idea in 3 tasks: prepare-close, then close-silva-incident and close-pagerduty in parallel.

### Trigger

| Setting | Value | What it means |
|---|---|---|
| Type | davis-problem | Same source as OPEN. |
| Filter | `event.status == "CLOSED"` | Only closed problems. |
| onProblemClose | true | Fire on close. |

### Task 1: prepare-close

| Output | Built from | Used for |
|---|---|---|
| correlation_id | display_id | Find the SILVA incident |
| dedup_key | `dt-problem-` + display_id | Resolve the PagerDuty alert |
| title, where, evidence | Problems API | Close notes |
| start, end, duration | Problems API | Close notes |

No input box. On manual Run, `SAMPLE_EVENT.display_id` is used.

### Task 2: find-silva-incident (GET only)

| GET | Why |
|---|---|
| `incident` where `correlation_id=<id>`, newest first | Find what OPEN created. Open one first, else the newest so the preview can say "already resolved". |
| `sys_choice` for `state` | Find SILVA's real value for "Resolved". |
| `sys_choice` for `close_code` | Check "Solved (Permanently)" exists. |

### Task 3: build-close-payload

| Part | Value |
|---|---|
| state | Resolved (real value from the list, usually 6) |
| close_code | CLOSE_CODE setting, matched to the list |
| close_notes | Problem id, close time, duration, cause, evidence |
| work_notes | Group, business service, offering, CI, Dynatrace link, PD key |
| PagerDuty body | event_action resolve, same dedup_key |
| Decision | Resolve SILVA only if an incident is found and still open. PagerDuty always. |

### Task 4a and 5a: SILVA branch

| Task | What happens |
|---|---|
| preview-silva-close | Checks incident found, open, state valid, close_code valid, close_notes filled. WRONG blocks. |
| resolve-silva-incident | Skips on decision, problems or sample. Re-reads the incident (someone may have closed it). PATCHes it. Fails if state did not become Resolved. |

### Task 4b and 5b: PagerDuty branch

| Task | What happens |
|---|---|
| preview-pagerduty-resolve | Checks event_action resolve and dedup_key format. |
| resolve-pagerduty | POSTs the resolve. PagerDuty ignores it if no alert is open. |

---

## Part 3: How OPEN and CLOSE fit together

### Shared keys

| System | OPEN writes | CLOSE reads |
|---|---|---|
| SILVA | `correlation_id = P-261090` on POST | GET `correlation_id = P-261090` |
| PagerDuty | trigger with `dedup_key = dt-problem-P-261090` | resolve with the same `dedup_key` |

### Life of one problem

| Time | Event | OPEN or CLOSE | SILVA | PagerDuty |
|---|---|---|---|---|
| T0 | Problem P-261090 created | OPEN runs | INC created, state New | Alert triggered |
| T0 + n | Dynatrace sends updates | Neither (OPEN only fires on CREATED) | No change | Same alert |
| T1 | Problem closes | CLOSE runs | INC PATCHed to Resolved | Alert resolved |
| T1 + | Problem reopens as a new P- id | OPEN runs again | New INC | New alert |

### What can go wrong

| Situation | What happens | What to do |
|---|---|---|
| OPEN skipped (maintenance or missing field) | CLOSE finds no incident, SILVA skips. PD resolve is harmless. | Nothing. |
| A person resolved the INC first | CLOSE sees it is not active and skips. | Nothing. |
| close_code not valid in SILVA | Seq 37 preview shows WRONG and skips. Seq 39 fails with the allowed list. | Fix CLOSE_CODE. |
| SILVA refuses Resolved | Resolve task fails: state did not change. | Add required fields to EXTRA_FIELDS. |
| Both close workflows active | Same close handled twice (second one skips, harmless but noisy). | Keep only one active. |
| Workflow still Draft | Not triggered by real problems. | Save / Deploy. |

### Safety settings in both

| Setting | Effect |
|---|---|
| DRY_RUN | true = build and show, never send. |
| ALLOW_SAMPLE_POST | false = manual Run never sends. |
| Preview gates | Send task skips if its preview is not ready. |
| Duplicate checks | OPEN never creates a second open INC for the same problem. |

## Data flow map

```
                 ┌──────────────────────── OPEN (problem created) ────────────────────────┐
Dynatrace ──────►│ tags + Problems API → SILVA GETs → payload → preview → POST / trigger │
P-261090         └──────────────┬───────────────────────────────────────┬─────────────────┘
                                │ correlation_id = P-261090             │ dedup_key = dt-problem-P-261090
                                ▼                                       ▼
                       SILVA stg INC (New)                      PagerDuty alert (triggered)
                                ▲                                       ▲
                                │ GET by correlation_id, PATCH          │ resolve same dedup_key
                 ┌──────────────┴───────────────────────────────────────┴─────────────────┐
Dynatrace ──────►│ prepare-close → find INC → close body → preview → PATCH / resolve     │
problem closed   └──────────────────────── CLOSE (problem closed) ─────────────────────────┘
```

## Related files

| File | Purpose |
|---|---|
| `36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml` | OPEN workflow (standard). |
| `37-close-workflow-preview-then-resolve/37-close-workflow-preview-then-resolve.workflow.yaml` | CLOSE with previews. |
| `39-close-direct-silva-pagerduty/39-close-direct-silva-pagerduty.workflow.yaml` | CLOSE direct. |
| `40.sh` | Lifecycle check queries for one problem id. |

## Commands

See `40.sh`. Line 1 shows the SILVA incident for a problem id (open or resolved). Line 2 lists close_code choices.
