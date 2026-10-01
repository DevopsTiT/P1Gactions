# Open And Close Workflows Line By Line

## Decision tree

```
Davis problem event arrives
 ├─ status ACTIVE + transition CREATED → OPEN workflow (seq 36)
 │    1 extract-event-tags   read event + tags → environment, app code, host, group tags
 │    2 resolve-snow-values  SILVA GETs → group, business service, offering, host CI, company
 │    3 build-payload        SILVA body + PagerDuty body + decision (create or skip)
 │    ├─ 4a preview-silva-incident → problems? → 5a post-silva-incident skips
 │    │                          → none    → 5a duplicate check → POST /incident
 │    └─ 4b preview-pagerduty     → ready?  → 5b trigger-pagerduty POST /v2/enqueue
 │
 └─ status CLOSED (trigger "closed") → CLOSE workflow (seq 45 v5)
      1 prepare-close   display_id, is_closed, times, cause
      ├─ 2a close-silva-incident → find active incidents by correlation_id
      │       → already Resolved? skip → else PATCH state + incident_state = Resolved
      │       → state did not change? → In Progress → Resolved
      └─ 2b close-pagerduty      → POST /v2/enqueue action resolve (same dedup_key)
```

## Short takeaway

| Question | Answer |
|---|---|
| What starts OPEN? | A new Davis problem (status ACTIVE, transition CREATED). |
| What starts CLOSE? | The same problem closing (trigger Event state "closed"). |
| How does CLOSE find what OPEN created in SILVA? | SILVA `correlation_id` = problem display id, for example P-261090. |
| How does CLOSE find what OPEN created in PagerDuty? | `dedup_key` = `dt-problem-` plus the display id. |
| Where are the safety stops in OPEN? | Decision in task 3, previews in 4a and 4b, duplicate check and sample check in 5a and 5b. |
| Where are the safety stops in CLOSE? | `is_closed` check, "already Resolved" filter, sample check, DRY_RUN. |
| Do SILVA and PagerDuty depend on each other? | No. Both workflows run the two branches in parallel, so one failing does not block the other. |

## Summary

Both workflows are Dynatrace "run JavaScript" tasks chained together. OPEN does the hard work: it reads the problem, looks up the right SILVA values, builds both request bodies, previews them, and then sends. CLOSE is small: it only needs the problem display id, because OPEN stored that id in SILVA (`correlation_id`) and in PagerDuty (`dedup_key`).

How to read this doc: each table covers one block of the file, with the line numbers on the left. Line numbers match:

- OPEN: `36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml`
- CLOSE: `45-close-direct-v5-trigger-closed/45-close-direct-v5-trigger-closed.workflow.yaml`

---

# Part A: OPEN workflow (seq 36, 1,248 lines)

## A0. Header comments, metadata, trigger (lines 1 to 51)

| Lines | What it does | Why it matters |
|---|---|---|
| 1 to 18 | Comments: what the workflow sends, the task order, and the safety switches. | Read this first after import; it is the user manual. |
| 14 | Pressing Run with no event uses the sample problem P-260916863. | Lets you test without waiting for a real problem. |
| 16 | Reminder to allowlist `silvastg.service-now.com` and `events.pagerduty.com`. | Without it, every `fetch` fails with "not allowed". |
| 18 | Warning that the file holds the SILVA password and PD routing key. | Never commit this file. |
| 19 to 25 | `metadata`: needs the `dynatrace.automations` app, and has no inputs. | No inputs means everything comes from the trigger event. |
| 27 | Title shown in the Workflows list. | Use it to tell versions apart. |
| 31 | `schemaVersion: 3` is the current workflow format. | Older versions import differently. |
| 34 | `isActive: true` turns the trigger on. | If false, only manual Run works. |
| 35 to 37 | `filterQuery`: only Davis problems that are ACTIVE and just CREATED. | Updates to an existing problem do not create a second incident. |
| 39 | `type: davis-problem` means "trigger on Davis problems". | This is the Problem trigger in the UI. |
| 41 to 46 | All five categories on (error, resource, slowdown, availability, custom). | Any problem type can open a ticket. |
| 47 | `entityTags: {}` means no tag filter. | Every entity counts. Add tags here to narrow it. |
| 48 | `onProblemClose: false` means do not run on close. | Closing is the CLOSE workflow's job. |
| 49 to 51 | Standard workflow, no input, at most 1,000 runs per hour. | The hourly limit protects against alert storms. |

## A1. Task 1 `extract-event-tags` (lines 53 to 310)

Purpose: turn the raw Dynatrace event into clean fields. No calls to SILVA.

| Lines | What it does | Why it matters |
|---|---|---|
| 53 to 62 | Task setup: run JavaScript, grid position column 0 row 1, no predecessors. | No predecessors means it runs first. |
| 64 | Imports `execution`, which reads the trigger event and other tasks' results. | Every task uses it. |
| 65 | Imports `problemsClient`, the Dynatrace Problems API v2. | Adds tags and evidence the event does not carry. |
| 66 | Imports `getEnvironmentUrl`. | Used to build the problem link. |
| 69 | `USE_PROBLEM_API = true`. | Set false if the API call fails or is slow. |
| 72 | `USE_MAINTENANCE_TAG = true`: the tag `AGO_Maintenance:True` also blocks tickets. | Teams can pause tickets by tag, not only by maintenance window. |
| 74 to 84 | `ENVIRONMENT` map: turns words like prd, uat, stg into SILVA labels. | SILVA only accepts its own labels, such as "Pre-Production". |
| 85 to 88 | Lists of tag keys to try for business service, app code, app name and company. | Different teams name tags differently. |
| 90 to 123 | `SAMPLE_EVENT`: a full copy of problem P-260916863. | Used only when you press Run. |
| 126 to 130 | `asList`: turns a value, array or comma string into a clean list. | Event fields come in different shapes. |
| 131 | `unique`: removes duplicates. | Keeps lists short. |
| 132 to 134 | `fmt`: turns any value into a printable string. | Used for the debug list of event fields. |
| 136 to 141 | `parseTag`: strips `[Kubernetes]` style prefixes, then splits `key:value`. | Makes every tag look the same. |
| 143 to 146 | `keyMatches`: compares lower case, and also with `-` changed to `_`. | `AGO-DEFAULT-ASSIGNMENT-GROUP` matches `ago_default_assignment_group`. |
| 147 to 150 | `findByKey`: first tag whose key passes a test. | Used for single values. |
| 151 to 161 | `allByKey`: every matching tag, in the order of the tests. | Gives a priority list, for example of group tags. |
| 163 to 168 | `envLabel`: whole value first, then each word. | `agportalfrontend-preprod-axa-li-jp` still gives "Pre-Production". |
| 170 to 175 | Main function: read the event; if it has no `event.kind` and no `event.id`, use the sample. | This is how manual Run works. |
| 177 to 186 | Call the Problems API with the event id; on error keep going and record why. | A failed API call never stops the workflow. |
| 188 to 193 | Merge tags from the event and from the API, without duplicates, then parse them. | The API often has tags the event lacks. |
| 195 to 199 | Group tags in priority order: `ago_axa_supportgroup`, then any `*assignment_group` or `*support_group`, then the default group tag. | The most specific group wins. |
| 200 | Business service tag (for example `snow-service`). | If present, task 2 uses it directly. |
| 203 to 218 | Environment, in order: environment tags, namespace, security context, patch tags, default. | Decides `u_environment` and which offering to pick. |
| 220 to 224 | Root cause name, affected names, types and ids. | Used for the title and the CI search. |
| 227 to 230 | App code from a tag, else from the `[CODE.ENV]` prefix of the service name. | App code drives the service search in task 2. |
| 232 to 238 | Other tags: DB type, domain, trigram, platform, region, host, maintenance. | Extra search hints for task 2. |
| 239 to 244 | Maintenance is true if the event says so, or (optionally) the tag says so. | Maintenance means no ticket. |
| 246 to 248 | Host name and service name, with fallbacks. | Used in the short description and CI search. |
| 249 to 252 | Error rate from API evidence, else from the description text, formatted like "10.29%". | Shown in the ticket. |
| 253 to 254 | Problem URL from the event, else built from the environment URL. | Clickable link in SILVA and PagerDuty. |
| 257 to 259 | CI search names: drop Dynatrace ids, `[CODE.ENV]` prefixes and wildcards. | SILVA CI names never look like `SERVICE-034688...`. |
| 261 to 287 | Returns `dynatrace_alert`: the readable alert facts. | Task 3 uses these for titles and text. |
| 288 to 303 | Returns `snow_inputs`: the hints for SILVA lookups. | Task 2 uses these. |
| 304 to 308 | Returns raw tags, environment id, and every event field (for debugging). | When something is wrong, look here first. |

## A2. Task 2 `resolve-snow-values` (lines 312 to 763)

Purpose: ask SILVA (GET only) for the real records: assignment group, business service, service offering, host CI and company.

| Lines | What it does | Why it matters |
|---|---|---|
| 312 to 325 | Setup: column 0 row 2, runs after task 1, only if task 1 is OK. | No clean input means no lookups. |
| 330 to 332 | SILVA stg URL, user and password. | Production rejects this account. |
| 333 to 338 | `SERVICE_MAP` and `GROUP_MAP`: manual overrides by app code. | Use when the automatic search picks wrong. |
| 345 | `GROUP_ORDER`: tag, enrichment, enrichment support, CI, default. | The first source that has a group wins. |
| 346 to 349 | Default group, business service, offering and environment label. | Used when nothing else is found. |
| 350 | Domains tried for host names (`hk.intraxa`, and so on). | `TS12` becomes `ts12.hk.intraxa`. |
| 351 | `MIN_SCORE = 5`. | A scored search guess must be at least this good. |
| 352 to 362 | Field lists for each table, and `NOT_OFFERING`. | Offerings live in the same table family as services, so they are excluded from service searches. |
| 365 to 368 | Basic auth header. | Same login for every call. |
| 371 to 388 | `getRows`: one Table API GET; never throws; records every call in `steps`. | `steps` in the output shows exactly what was asked. |
| 390 to 391 | `dv` gives the display name, `val` gives the stored value (sys_id). | SILVA returns both when `display_value=all`. |
| 392 | `active`: prefer an operational row. | Avoids retired records. |
| 393 to 394 | `isSysId` and `has` helpers. | Small checks used below. |
| 396 to 402 | `groupByName`: look up an active group in `sys_user_group`. | Proves a tag group really exists. |
| 403 to 410 | `serviceByName` and `serviceById` in `cmdb_ci_service`. | Business service lookups. |
| 411 to 430 | `findCis`: host by name or FQDN (with domains), then "starts with", then other names. | Finds the host CI, for example ts12.hk.intraxa. |
| 432 to 444 | `servicesForCi`: services linked to a CI through its fields, `svc_ci_assoc`, and `cmdb_rel_ci`. | Three ways SILVA links a server to a service. |
| 445 to 458 | `score`: points for group, app code, DB type, environment, region, trigram, operational, business class. | Ranks search results. |
| 460 to 467 | Main: read task 1's `snow_inputs`; build keys for the maps. | Starting point. |
| 469 to 485 | Step 1, tag group: from `GROUP_MAP`, else the first group tag that exists in SILVA. | Becomes the "tag" source. |
| 487 to 500 | Search terms object `t`. | Shared by the searches. |
| 502 to 507 | Service path A: `SERVICE_MAP` or the business service tag. | Most reliable when set. |
| 509 to 524 | Service path B: host CI, then the services linked to it. | Usual path for server problems. |
| 526 to 555 | Service path C: several searches merged and scored; best must reach `MIN_SCORE` and beat second place. | Avoids picking a tie at random. |
| 557 to 574 | Service path D: first answer by app code or group, preferring a name with the environment. | Weaker guess, used only if C fails. |
| 576 to 581 | Service path E: default business service. | Last resort. "Default set" means no service and no group tag. |
| 583 to 600 | If the chosen CI service has no offering, switch to another CI service that has one. | No offering means a missing mandatory field. |
| 602 to 606 | If the result is actually an offering, use its parent as the service. | Keeps service and offering consistent. |
| 608 to 612 | Keep the event environment; use the default label only in "default set". | Do not overwrite real data. |
| 614 | The first CI found is the host CI. | Goes into `u_configuration_item`. |
| 616 to 637 | Final assignment group by `GROUP_ORDER`. | Which team gets the ticket. |
| 639 to 651 | Offering: the service's offering whose environment matches. | Correct offering for Pre-Production versus Production. |
| 652 to 655 | Else the offering found by the service search. | Fallback. |
| 656 to 680 | Else the offering most used on the last 20 incidents for this host CI (and its business service). | This is how P-261090 got offering cfbf255f (20 of 20). |
| 681 to 696 | Else default offering, first offering of the service, or first offering of the group. | Final fallbacks. |
| 698 to 704 | Company: from the service, else the CI, else the group. | Mandatory on the form. |
| 706 to 719 | `snow_required`: the final values with sys_ids and where each came from. | Task 3 builds the body from this. |
| 721 to 739 | `servicenow_enrichment`: the business service details. | Shown for checking. |
| 741 to 762 | Returns everything, plus candidates, CIs, history and `steps`. | Explains every choice. |

## A3. Task 3 `build-payload` (lines 765 to 922)

Purpose: build the SILVA incident body and the PagerDuty body, and decide create or skip. No network calls.

| Lines | What it does | Why it matters |
|---|---|---|
| 765 to 777 | Setup: column 0 row 3, after task 2 OK. | |
| 783 | `SHORT_PREFIX = "[DYNATRACE JAPAN]"`. | Start of every ticket title. |
| 784 to 787 | Caller and On Behalf Of = Dynatrace JP (sys_id `8ddef691...`). | Taken from a real ticket, INC30340215. |
| 788 | `contact_type = event`. | Marks it as a monitoring ticket. |
| 789 | Host CI goes in `u_configuration_item`. | SILVA's form label "Configuration item". |
| 790 to 795 | Default company, category, subcategory, impact 4, urgency 4, Dynatrace environment name. | Fixed values. |
| 797 | `ENV_VALUE`: optional map from label to stored value. | Only if SILVA stores a code instead of the label. |
| 800 to 806 | Read tasks 1 and 2. | |
| 808 to 809 | Target = CI FQDN, else CI name, else service name; title = prefix + target + event name, max 160 characters. | Example: `[DYNATRACE JAPAN][ts12.hk.intraxa] - Error in ...`. |
| 811 to 825 | "Additional Information" block for the description. | Line 814 prints the entity id as text; the real `correlation_id` field is set on line 848. |
| 827 to 849 | List of every field: name, value, and where the value came from. | One place to see the whole body. |
| 837 to 839 | `u_business_service` = business service, `cmdb_ci` = Service Offering. | The plain `business_service` field is "ZZZ-Do-not-use" in SILVA. |
| 848 | `correlation_id` = problem display id. | The key CLOSE uses to find this ticket. |
| 851 to 852 | Build the body, dropping empty values. | SILVA does not get blank fields. |
| 854 to 867 | `field_sources`: value, display name and source for each field. | Preview 4a prints these. |
| 869 to 874 | Missing check: group, business service, offering, environment, title. | Any missing means no ticket. |
| 875 to 879 | `decision`: create only if nothing is missing and maintenance is off. | Main stop switch. |
| 881 to 907 | PagerDuty body: action trigger, `dedup_key = dt-problem-<id>`, summary, source, severity, details. | The routing key is a placeholder here; 5b adds the real one. |
| 890 | Severity "error" for Infrastructure impact, else "warning". | Controls PD urgency. |
| 909 to 921 | Output: decision, both bodies, sources, environment. | Read by 4a, 4b, 5a, 5b. |

## A4. Task 4a `preview-silva-incident` (lines 924 to 1031)

Purpose: check the SILVA body field by field and look for an existing open ticket. GET only.

| Lines | What it does | Why it matters |
|---|---|---|
| 924 to 936 | Setup: column 0 row 4, after task 3 OK. | |
| 954 to 971 | `FORM`: each form label, its API key, whether it is mandatory, whether it needs a sys_id. | Matches the SILVA incident form. |
| 980 to 995 | Each field becomes OK, MISSING (mandatory and empty), EMPTY (optional) or WRONG (needs a 32-character sys_id but is a name). | Catches bodies SILVA would reject or mis-link. |
| 997 to 1011 | GET for an active incident with the same `correlation_id`. | Shows a duplicate before posting. |
| 1013 | `problems` = fields that are MISSING or WRONG. | 5a skips if this is not empty. |
| 1014 to 1017 | `open_v7_would`: CREATE, or SKIP with the reason. | Plain-English forecast. |
| 1019 to 1030 | Output `ready`, `problems`, field checks, duplicate check, body. | The screenshots you sent show this. |

## A5. Task 4b `preview-pagerduty` (lines 1033 to 1078)

| Lines | What it does | Why it matters |
|---|---|---|
| 1033 to 1045 | Setup: column 1 row 4, after task 3 OK. | Runs side by side with 4a. |
| 1053 to 1055 | Copy the PD body, hide the routing key, add a link to the problem. | Safe to share the output. |
| 1058 to 1064 | Five checks: action is trigger, dedup key starts with `dt-problem-P-`, summary present and at most 1,024 characters, source present, valid severity. | PagerDuty rejects bad bodies. |
| 1066 to 1068 | Forecast: SEND, or NOT send with the reason. | |
| 1069 to 1077 | Output with `ready`. | 5b reads `ready`. |

## A6. Task 5a `post-silva-incident` (lines 1080 to 1180)

Purpose: create the SILVA incident, after all gates pass.

| Lines | What it does | Why it matters |
|---|---|---|
| 1088 to 1092 | Runs only after 4a, only if 4a is OK. | Hangs directly under its preview. |
| 1101 | `DRY_RUN = false`. | Set true to log the body without posting. |
| 1102 | `ALLOW_SAMPLE_POST = false`. | Manual Run never makes a real ticket unless you change this. |
| 1119 to 1121 | Gate 1: task 3 decision says skip. | Missing fields or maintenance. |
| 1122 to 1124 | Gate 2: preview found MISSING or WRONG fields. | |
| 1125 to 1127 | Gate 3: sample event and posting samples not allowed. | |
| 1129 to 1145 | Gate 4: GET again for an active incident with this `correlation_id`; if found, return "exists". | One ticket per problem, even if the workflow reruns. |
| 1147 to 1150 | DRY_RUN: print and stop. | |
| 1152 to 1156 | POST to `/api/now/v2/table/incident`. | Creates the ticket. |
| 1160 to 1162 | Any non-2xx answer throws, so the task turns red with SILVA's message. | You see the real error. |
| 1163 to 1179 | Output: number, sys_id, state, group, service, offering, CI, environment, link. | Example: INC30341416. |

## A7. Task 5b `trigger-pagerduty` (lines 1182 to 1248)

| Lines | What it does | Why it matters |
|---|---|---|
| 1190 to 1194 | Runs only after 4b, only if 4b is OK. | Parallel to 5a. |
| 1200 | Real routing key. | Points to your PD service. |
| 1205 to 1207 | Comment: SILVA number is unknown here; the link is the problem id. A repeat trigger with the same dedup key does not open a new PD incident. | PagerDuty de-duplicates for you. |
| 1213 to 1221 | Gates: decision, preview `ready`, sample event. | Same idea as 5a. |
| 1223 to 1225 | Copy the body, insert the real key, add the link. | |
| 1227 to 1229 | DRY_RUN returns the body with the key hidden. | |
| 1231 to 1235 | POST to `https://events.pagerduty.com/v2/enqueue`. | PagerDuty Events API v2. |
| 1237 to 1239 | Non-2xx throws. | Task turns red. |
| 1242 to 1247 | Output: triggered, status, dedup key, problem id. | |

Gate difference worth knowing: 5a checks the preview's `problems` list, while 5b checks the preview's `ready` flag. Both also check the task 3 decision, so the result is the same in practice.

---

# Part B: CLOSE workflow (seq 45 v5, 426 lines)

## B0. Header, metadata, trigger (lines 1 to 58)

| Lines | What it does | Why it matters |
|---|---|---|
| 1 to 11 | Version history v2 to v5. | Explains each fix. |
| 12 to 14 | The two sync keys shared with OPEN. | This is the whole link between the workflows. |
| 16 to 19 | Task list: prepare, then SILVA and PagerDuty in parallel. | PD resolves even if SILVA fails. |
| 21 to 22 | Run with no event uses the sample; DRY_RUN for testing. | |
| 23 | Allowlist both hosts and Deploy. | Drafts never fire. |
| 24 | Use this or seq 37, not both. | Otherwise the same close is handled twice. |
| 34 | Title v5. | |
| 42 to 43 | `filterQuery`: Davis problem with status CLOSED. | Extra filter. |
| 54 | `triggerOn: close`. | The "closed" Event state. |
| 55 | `onProblemClose: true`. | Old switch, kept for older tenants. |
| 56 to 58 | Standard type, no input, 1,000 runs per hour. | |

## B1. Task 1 `prepare-close` (lines 60 to 150)

| Lines | What it does | Why it matters |
|---|---|---|
| 60 to 68 | Setup: column 0 row 1, no predecessors. | Runs first. |
| 71 to 73 | Same three imports as OPEN task 1. | |
| 76 | `USE_PROBLEM_API = true`. | Gets exact start and end times. |
| 78 to 84 | `SAMPLE_EVENT` for manual Run; only `display_id` really matters. | Change it to close a different test problem. |
| 87 | `first`: first item of an array. | |
| 88 to 94 | `toMs`: turns numbers or dates into milliseconds; very large numbers are treated as nanoseconds. | Dynatrace sometimes sends nanoseconds. |
| 95 to 99 | `duration`: "42 min" or "2 h 5 min". | Used in the notes. |
| 101 to 106 | Read the event, or use the sample. | |
| 108 to 117 | Problems API call; errors are recorded, not thrown. | |
| 119 to 120 | Internal id and display id (P-261090). | Display id is the sync key. |
| 121 to 122 | Start and end time; end defaults to now. | |
| 123 to 124 | Where it happened: root cause name, else affected entity. | |
| 126 to 131 | `is_closed`: API status CLOSED, or (without API) event status CLOSED or transition RESOLVED or CLOSED. | Second safety net. The comment on line 126 still mentions "active or closed" from v4; the code is still correct. |
| 133 to 149 | Output: is_closed, the check text, problem id, `correlation_id`, `dedup_key`, title, where, times, duration, URL, sample flag. | Both close tasks read this. |

## B2. Task 2a `close-silva-incident` (lines 152 to 364)

| Lines | What it does | Why it matters |
|---|---|---|
| 152 to 164 | Setup: column 0 row 2, after prepare-close OK. | |
| 170 to 172 | SILVA stg login. | |
| 174 to 175 | Target state "Resolved"; middle state "In Progress". | Label or value both work. |
| 177 | `STATE_FIELDS = ["state", "incident_state"]`. | The v2 fix: SILVA's form uses `incident_state`. |
| 179 | `STEP_THROUGH_IN_PROGRESS = true`. | Backup path if New to Resolved is refused. |
| 181 | `ASSIGNED_TO = ""`. | Not needed on SILVA stg. |
| 182 | `CLOSE_CODE = "Solved (Permanently)"`. | Confirmed as a valid SILVA choice. |
| 184 | `NOTES_FIELD = "work_notes"`. | Internal note; "comments" would be visible to the caller. |
| 186 | `EXTRA_FIELDS = {}`. | Add fields here if SILVA ever requires more. |
| 187 to 188 | `DRY_RUN` and `ALLOW_SAMPLE_POST`. | Same meaning as in OPEN. |
| 191 to 197 | Auth header and the `val` and `dv` helpers. | |
| 199 to 210 | `getRows`: GET that throws on errors. | Unlike OPEN, a failed lookup stops this task. |
| 212 to 227 | `choiceValue`: read `sys_choice` and turn "Resolved" into SILVA's stored value; throw if it does not exist. | Avoids sending a value SILVA silently ignores. |
| 229 to 232 | `softChoice`: same, but falls back instead of throwing. | Used for the optional values. |
| 233 to 252 | `patch`: PATCH one incident and return state and incident_state (value and label). | Lets the code check what really changed. |
| 257 to 259 | Guard: skip if the problem is not closed. | |
| 261 to 265 | Look up the values for state, close code, In Progress, and incident_state. | |
| 266 to 272 | `stateBody`: one body that sets both state fields; `RESOLVED` and `IN_PROGRESS` targets. | |
| 274 to 276 | GET up to 5 active incidents with this `correlation_id`, newest first. | Finds what OPEN created. |
| 277 to 280 | Drop incidents already Resolved on either field. | Resolved tickets stay "active" until Closed, so this avoids touching them again. |
| 281 to 283 | Nothing left: skip and list what was found. | For example, OPEN skipped that problem. |
| 284 to 286 | Sample event and not allowed: skip and show what would be resolved. | |
| 288 to 293 | `close_notes`: closed time, duration, cause, recovery line. | Required text for resolving. |
| 296 to 309 | Per incident: a work note with duration, cause, group, service, offering, CI, links. | Audit trail in Activities. |
| 311 | `notesDone`: close code already set means notes were written by an earlier run. | Stops duplicate notes (v3 fix). |
| 312 to 314 | First body: both state fields, close code, notes (if not done), extra fields. | |
| 316 to 319 | DRY_RUN: record the body and move on. | |
| 321 to 324 | PATCH; success only if state or incident_state is now Resolved. | v1 only trusted HTTP 200, which hid the real failure. |
| 326 to 332 | If not resolved: PATCH to In Progress, then Resolved again. | Backup for strict state rules. |
| 334 to 345 | Result per incident: before, after, which attempt worked, all attempts, error, link. | |
| 348 to 358 | Output: overall action, value checks, incidents. | |
| 360 to 362 | If any incident failed, throw so the task turns red. | You notice failures. |

## B3. Task 2b `close-pagerduty` (lines 366 to 426)

| Lines | What it does | Why it matters |
|---|---|---|
| 366 to 378 | Setup: column 1 row 2, after prepare-close OK. | Parallel to SILVA. |
| 384 to 386 | Routing key, DRY_RUN, ALLOW_SAMPLE_POST. | |
| 389 | Comment: PagerDuty ignores a resolve with no matching open alert. | Safe to always send. |
| 394 to 396 | Guard: problem not closed means skip. | |
| 397 to 399 | Skip if the dedup key has no problem id. | Avoids resolving `dt-problem-` with nothing after it. |
| 400 to 402 | Sample gate. | |
| 404 | Body: routing key, action `resolve`, dedup key. | Same dedup key as OPEN 5b. |
| 405 to 407 | DRY_RUN. | |
| 409 to 417 | POST to `/v2/enqueue`; non-2xx throws. | |
| 420 to 425 | Output: resolved, status, dedup key, problem id. | |

---

## Data flow map

```
Davis problem P-261090 CREATED
  └─ OPEN
      extract-event-tags ── event + Problems API ──► alert facts + SILVA hints
      resolve-snow-values ── GET sys_user_group, cmdb_ci, cmdb_ci_service,
                             svc_ci_assoc, cmdb_rel_ci, service_offering, incident
                             ──► group, business service, offering, host CI, company
      build-payload ──► SILVA body (correlation_id = P-261090)
                    ──► PD body   (dedup_key = dt-problem-P-261090)
      ├─ preview-silva-incident ─► post-silva-incident ─► POST /incident ─► INC30341416
      └─ preview-pagerduty     ─► trigger-pagerduty   ─► POST /v2/enqueue trigger

Davis problem P-261090 CLOSED
  └─ CLOSE
      prepare-close ──► is_closed, correlation_id, dedup_key, duration, cause
      ├─ close-silva-incident ─► GET incident where correlation_id = P-261090
      │                        ─► PATCH state + incident_state = Resolved, close_code, notes
      └─ close-pagerduty      ─► POST /v2/enqueue resolve dt-problem-P-261090
```

## Investigation

| What I checked | What I found |
|---|---|
| OPEN file | Seq 36 standard copy, 1,248 lines, seven tasks. |
| CLOSE file | Seq 45 v5, 426 lines, three tasks. |
| Sync keys in both files | OPEN line 848 and CLOSE line 137 use the display id; OPEN line 884 and CLOSE line 139 use `dt-problem-<id>`. |
| Small things noticed | CLOSE line 126 comment is out of date (code is fine). OPEN line 814 prints the entity id labelled "correlation_id" inside the description text only. |

## Result

| If you want to... | Change this |
|---|---|
| Test OPEN without sending | `DRY_RUN = true` in 5a (line 1101) and 5b (line 1201). |
| Test CLOSE without sending | `DRY_RUN = true` in 2a (line 187) and 2b (line 385). |
| Force a business service | `SERVICE_MAP` in OPEN task 2 (line 333). |
| Force an assignment group | `GROUP_MAP` in OPEN task 2 (line 336). |
| Close a test problem by hand | CLOSE `SAMPLE_EVENT.display_id` (line 81) plus `ALLOW_SAMPLE_POST = true` in 2a and 2b. |
| Use public comments instead of work notes | CLOSE line 184 `NOTES_FIELD = "comments"`. |

## Related files

| File | What it is |
|---|---|
| `36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml` | Latest OPEN |
| `45-close-direct-v5-trigger-closed/45-close-direct-v5-trigger-closed.workflow.yaml` | Latest CLOSE |
| `41-how-to-build-workflows-apis-discovery/41.sh` | Discovery queries behind these lookups |
| `46.sh` | Commands to view each block by line number |

## Commands

See [`46.sh`](46.sh). Example:

```bash
sed -n '1080,1180p' "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml"
```
