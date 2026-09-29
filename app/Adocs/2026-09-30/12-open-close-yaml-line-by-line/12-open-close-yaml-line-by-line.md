# OPEN And CLOSE YAML Line By Line

## Decision tree

```
Reading a Dynatrace workflow YAML
 │
 ├─ lines starting with "#" ─────────── comments for humans, ignored by Dynatrace
 ├─ metadata ────────────────────────── which Dynatrace app the workflow needs
 ├─ workflow.title / description ───── what you see in the Workflows list
 ├─ workflow.trigger ────────────────── WHEN it runs (event filter)
 ├─ workflow.tasks ──────────────────── WHAT it does, one block per task
 │    ├─ action ─────────────────────── run-javascript = run the script below
 │    ├─ predecessors + conditions ──── ORDER (run after task X, only if X was OK)
 │    ├─ position ───────────────────── where the box sits on the canvas
 │    └─ input.script ───────────────── the JavaScript that does the work
 │         ├─ imports ───────────────── Dynatrace SDK helpers
 │         ├─ settings block ────────── values you edit
 │         ├─ helper functions ──────── small reusable pieces
 │         └─ export default function ─ runs once per execution, returns the task result
```

## Short takeaway

| Question | Answer |
|---|---|
| Which files? | `9-v6-full-open-silva-pagerduty.workflow.yaml` (OPEN, 1021 lines) and `11-v6-close-silva-pagerduty.workflow.yaml` (CLOSE, 343 lines) |
| What is YAML here? | The outer frame: trigger, task list, order |
| Where is the real logic? | In each task's `script: |` block (JavaScript) |
| How do tasks share data? | Each task `return`s an object; later tasks read it with `ex.result("<task name>")` |
| Which lines hold secrets? | OPEN 318, 885, 976 and CLOSE 209, 311 (password and routing key) |

## Summary

Both files share the same shape: comments, metadata, trigger, then tasks. Each task is a box on the Dynatrace canvas that runs one JavaScript function. The function reads the event or an earlier task's result, does its work, and returns an object that the next task can read.

---

# Part 1 — OPEN workflow (`9-v6-full-open-silva-pagerduty.workflow.yaml`)

## Lines 1 to 37 — header comments

| Lines | What they say |
|---|---|
| 1 | Name of the workflow and the whole path: problem, SILVA incident, PagerDuty |
| 2 to 7 | The five tasks in order, one per line |
| 8 | Tasks 4 and 5 do nothing when the decision says no |
| 9 | How to test without sending (DRY_RUN) |
| 10 | PagerDuty host must be allowlisted |
| 12 to 18 | The default set values used when nothing is found |
| 20 to 25 | What task 3 outputs |
| 26 to 31 | History: what v4 changed (group order, environment order, maintenance) |
| 32 | Pressing Run uses the sample event |
| 33 to 36 | Checklist before activating |

Comments start with `#`. Dynatrace ignores them.

## Lines 38 to 44 — metadata

| Line | Code | Meaning |
|---|---|---|
| 38 | `metadata:` | Start of the technical header |
| 39 | `version: "1"` | Format version of this export |
| 40 to 43 | `dependencies: apps: - id: dynatrace.automations` | The workflow needs the Automations app (which provides run-javascript) |
| 43 | `version: ^1.3301.5` | Minimum app version |
| 44 | `inputs: []` | No input values are asked when importing |

## Lines 45 to 51 — workflow identity

| Line | Code | Meaning |
|---|---|---|
| 45 | `workflow:` | Start of the workflow itself |
| 46 | `title:` | Name shown in the Workflows list |
| 47 to 50 | `description: >-` | Longer text. `>-` joins the next lines into one sentence |
| 51 | `schemaVersion: 3` | Dynatrace workflow format version 3 |

## Lines 52 to 70 — trigger

| Line | Code | Meaning |
|---|---|---|
| 52 | `trigger:` | When the workflow runs |
| 53 | `eventTrigger:` | It runs on an event (not a schedule) |
| 54 | `isActive: true` | Trigger is switched on |
| 55 to 57 | `filterQuery:` | Only events that match: a Davis problem, ACTIVE, and just CREATED |
| 58 to 59 | `triggerConfiguration: type: davis-problem` | Use the Davis problem trigger type |
| 61 to 66 | `categories:` | Which problem types: error, resource, slowdown, availability, custom |
| 67 | `entityTags: {}` | No tag filter; every entity can trigger it |
| 68 | `type: STANDARD` | Normal workflow |
| 69 | `input: {}` | No workflow inputs |
| 70 | `hourlyExecutionLimit: 1000` | Safety cap: max 1000 runs per hour |

## Lines 71 to 82 — task frame (same pattern for all tasks)

| Line | Code | Meaning |
|---|---|---|
| 71 | `tasks:` | List of tasks starts |
| 72 | `extract-event-tags:` | Task id (used by other tasks to read its result) |
| 73 | `name:` | Display name |
| 74 | `description:` | Text shown on the task box |
| 75 | `action: dynatrace.automations:run-javascript` | This task runs JavaScript |
| 76 | `active: true` | Task is enabled |
| 77 to 79 | `position: x: 0 y: 1` | Box position on the canvas (column 0, row 1) |
| 80 | `predecessors: []` | No task before it, so it runs first |
| 81 to 82 | `input: script: |` | The script follows; `|` keeps line breaks exactly |

## TASK 1 script — lines 83 to 296

### Imports (83 to 85)

| Line | Import | Used for |
|---|---|---|
| 83 | `execution` | Get the current run: the trigger event and earlier task results |
| 84 | `problemsClient` | Call the Dynatrace Problems API |
| 85 | `getEnvironmentUrl` | Your tenant URL, for building the problem link |

### Settings (87 to 129)

| Lines | Setting | Meaning |
|---|---|---|
| 88 | `USE_PROBLEM_API = true` | Try the Problems API for extra detail |
| 90 to 96 | `ENVIRONMENT` | Maps tag values (lower case) to SILVA labels, for example `acceptance` to "Integration / Test" |
| 97 | `DEFAULT_ENVIRONMENT` | Label used when nothing matches |
| 98 | `SERVICE_TAG_KEYS` | Tag keys that can hold a business service name |
| 100 to 128 | `SAMPLE_EVENT` | A copy of your Oracle event, used when you press Run by hand |

### Helper functions (131 to 160)

| Lines | Function | What it does |
|---|---|---|
| 131 to 133 | `asList(v)` | Turns a value into a clean list of strings (handles missing values and single values) |
| 134 | `unique(a)` | Removes duplicates and empty values |
| 137 to 142 | `parseTag(raw)` | Removes a `[Context]` prefix, splits at the first `:` into key and value |
| 144 to 147 | `findByKey(parsed, test)` | Returns the first tag whose lower-case key passes the test |
| 150 to 160 | `allByKey(parsed, tests)` | Returns all matching tags, in the order of the tests, without repeating a value |

### Main function (162 to 296)

| Lines | Code idea | What it does |
|---|---|---|
| 162 | `export default async function ({ executionId })` | Entry point Dynatrace calls |
| 163 | `execution(executionId)` | Get this run |
| 164 | `ex.event()` | The trigger event (empty on manual Run) |
| 165 | `usedSample` | True when there is no real event |
| 166 | `ev` | Real event, or SAMPLE_EVENT |
| 167 | `envUrl` | Tenant URL without the trailing `/` |
| 169 to 178 | Problems API call | Only for real events; on error, saves the message and continues |
| 180 | `rawTags` | Tags from `entity_tags` |
| 181 to 184 | Add Problems API tags | Adds tags not already in the list |
| 185 | `parsed` | Every tag split into key and value |
| 186 to 187 | `byKey` | Key to value map (a key seen twice becomes a list) |
| 188 to 190 | `agoTags` and `otherTags` | Tags sorted into AGO_ tags and the rest |
| 193 to 197 | `groupCandidates` | Test 1: support group tag. Test 2: specific assignment or support group tags. Test 3: default group tag |
| 200 | `serviceTag` | First tag whose key is in SERVICE_TAG_KEYS |
| 203 to 208 | `envCandidates` | Environment tags in priority order; patch-environment last |
| 209 to 211 | `ctxEnv` | Last word of the longest security context (for example `..._dev` gives `dev`) |
| 212 | `envHit` | First environment tag whose value is in the ENVIRONMENT map |
| 213 to 217 | `environment` | Tag result, else security context, else default; each with `from` |
| 220 | `dbType` | Tag `ago_db` |
| 221 | `domain` | Tag `ago_domain`, else any key with `domain` |
| 222 to 224 | `trigram`, `platform`, `region` | Keys containing those words |
| 225 | `hostTag` | Tag `host` |
| 226 to 232 | `maintenance` | Event field first, then the AGO_Maintenance tag, else false |
| 235 to 237 | Affected names and types | `typeNames` reads the field named in `affected_entity_types` (that is where DEA10B01 lives) |
| 238 | `rootName` | Root cause name from the Problems API or event |
| 239 | `entityIds` | Dynatrace entity ids |
| 240 | `hostName` | Host tag, else `host.name`, else `dt.entity.host.name` |
| 241 | `serviceName` | Best display name: root cause, affected name, entity field, host, id |
| 242 to 245 | `errorRate` | From Problems API evidence; formats a number as a percent |
| 246 to 247 | `problemUrl` | Event URL, else built from the tenant URL |
| 249 to 269 | `dynatraceAlert` | The alert summary object (name, severity, ids, environment, tags, maintenance) |
| 271 to 295 | `return {...}` | The task result |

### Task 1 result fields

| Field | Content |
|---|---|
| `usedSample` | True on manual Run |
| `problemApi` | ok, off, skipped or the error text |
| `dynatrace_alert` | Alert summary |
| `snow_inputs` | Group candidates, service tag, environment, maintenance, security context, db type, domain, trigram, region, host |
| `snow_inputs.db_or_entity_names` (286 to 287) | Names for CI search; Dynatrace ids like `CUSTOM_DEVICE-...` removed by regex |
| `tags` | Count, AGO tags, other tags, raw list |
| `dt_environment_id` (290) | First part of the tenant host name |
| `event_properties` (291 to 293) | Every event field as key and value, max 300 characters |
| `eventKeys` | List of event field names (for debugging) |

## TASK 2 frame — lines 298 to 312

| Line | Code | Meaning |
|---|---|---|
| 298 | `resolve-snow-values:` | Task id |
| 303 to 305 | `position: x: 0 y: 2` | Second row |
| 306 to 307 | `predecessors: - extract-event-tags` | Runs after task 1 |
| 308 to 310 | `conditions: states: extract-event-tags: OK` | Runs only if task 1 succeeded |

## TASK 2 script — lines 313 to 685

### Settings (315 to 342)

| Lines | Setting | Meaning |
|---|---|---|
| 316 | `BASE_URL` | SILVA address |
| 317 to 318 | `USERNAME`, `PASSWORD` | API user (secret on line 318) |
| 320 to 322 | `SERVICE_MAP` | Fixed business service per trigram, tag or entity name (empty) |
| 323 to 325 | `GROUP_MAP` | Fixed group per trigram, tag or entity name (empty) |
| 326 | `DEFAULT_GROUP` | Ops_Middleware_Monitoring_AXAJP |
| 329 | `DEFAULT_BUSINESS_SERVICE` | QA Platforms |
| 330 | `DEFAULT_SERVICE_OFFERING` | Start of the default offering name |
| 331 | `DEFAULT_ENVIRONMENT_LABEL` | PoC / VoA / Demo (default set only) |
| 332 | `DOMAINS` | DNS suffixes tried for the host |
| 333 | `MIN_SCORE` | Minimum points for a scored search pick |
| 334 to 339 | `SERVICE_FIELDS` | Columns read from business service records |
| 340 to 341 | `CI_FIELDS` | Columns read from CI records |

### Shared helpers (344 to 440)

| Lines | Name | What it does |
|---|---|---|
| 344 to 347 | `headers` | Basic authentication header (user and password in base64) |
| 348 | `steps` | Log of every SILVA call |
| 350 to 367 | `getRows(label, table, query, fields, limit)` | Builds the Table API URL, runs GET, never throws, returns rows and logs the call |
| 354 | `sysparm_display_value=all` | Each field comes back as `{ value, display_value }` so we get both sys_id and name |
| 369 | `dv(row, f)` | Display value (the name) |
| 370 | `val(row, f)` | Stored value (usually the sys_id) |
| 371 | `active(rows)` | Prefers an operational or installed row |
| 372 | `isSysId(v)` | True for a 32-character hex id |
| 373 | `has(text, word)` | Case-insensitive "contains" |
| 375 to 381 | `groupByName` | Looks up an active group by exact name; returns name, sys_id and company |
| 383 | `envLabelOf` | Environment label from task 1 inputs |
| 385 to 388 | `serviceByName` | Business service by exact name |
| 390 to 393 | `serviceById` | Business service by sys_id |
| 395 to 414 | `findCis` | Host by name, fqdn, domains, then "starts with"; DB by exact name, then "contains"; max 4 CIs |
| 416 to 426 | `serviceForCi` | CI own field (only a real sys_id), then `svc_ci_assoc`, then `cmdb_rel_ci` parent service |
| 428 to 440 | `score(row, t)` | Points: group 3, DB type 2, environment 2, trigram 2, region 1, operational 1, business class 1; also returns reasons |

### Main function (442 to 685)

| Lines | Block | What it does |
|---|---|---|
| 443 to 446 | Read task 1 | `p` = task 1 result, `si` = snow_inputs |
| 447 to 449 | `mapKeys` and `fromMap` | Keys used to look into SERVICE_MAP and GROUP_MAP (trigram, service tag, entity names) |
| 452 to 459 | Group step 1 | GROUP_MAP name checked in SILVA |
| 460 to 465 | Group step 2 | Each tag candidate checked; first found wins, `verified: true` |
| 467 to 470 | Group step 3 | Keep the first tag name even if SILVA did not confirm it |
| 473 to 483 | Search terms `t` | Group sys_id and name, db type, environment tag, region prefix (`AP-SOUTHEAST-1` becomes `AP-SOUTHEAST`), trigram |
| 486 to 490 | Path A | SERVICE_MAP or service tag, exact name |
| 493 | `domains` | Domain tag first, then DOMAINS, no repeats |
| 494 | `cis` | Host and DB CIs found |
| 495 to 503 | Path B | For each CI, find its service; stop at the first |
| 506 to 516 | Path C searches | Up to five queries built only if their inputs exist |
| 517 to 525 | Merge | Pool by sys_id, remember which searches found each row |
| 526 to 528 | Rank | Score plus one per extra search; sort high to low |
| 529 to 534 | Pick | Best score at least 5 and higher than the second |
| 540 to 557 | Path D | First answer by group, support group, trigram, db type; environment match first, else first row |
| 559 | `ci` | First CI (used for company, group fallback and payload) |
| 560 to 568 | `defaultOffering()` | Offering under QA Platforms starting with the default name; else by name only |
| 571 | `defaultSet` | True when no service and no group |
| 575 to 583 | Default set | Sets service, group, offering and environment together |
| 586 to 589 | Path E | Service still empty: QA Platforms |
| 592 to 598 | Group fallback | Service group, service support group, CI support group, default |
| 601 to 612 | Offering from service | Environment match, name match, else first offering |
| 613 to 622 | Offering from group | First offering owned by the group |
| 623 to 626 | Offering default | Default offering |
| 628 to 644 | `snowRequired` | Final answers, each with `from`; company order is service, CI, group |
| 646 to 666 | `enrichment` | correctoutput.sh layout of the chosen service |
| 668 to 684 | `return {...}` | snow_required, enrichment, group checks, search terms, first answer rows, candidates, CIs, steps |

## TASK 3 frame — lines 687 to 701

Same pattern: id `display-result`, row 3, runs after `resolve-snow-values` only if it was OK.

## TASK 3 script — lines 702 to 863

### Settings (704 to 726)

| Line | Setting | Meaning |
|---|---|---|
| 707 | `SHORT_PREFIX` | `[DYNATRACE JAPAN]` |
| 708 | `SKIP_WHEN_MAINTENANCE` | No ticket during maintenance |
| 709 | `CALLER` | Caller name |
| 710 | `ON_BEHALF_OF` | On Behalf Of name |
| 711 | `CONTACT_TYPE` | Stored value for "Event" |
| 712 | `DEFAULT_COMPANY` | AXA GROUP OPERATIONS |
| 713 to 716 | `CATEGORY`, `SUBCATEGORY`, `IMPACT`, `URGENCY` | Stored choice values |
| 717 | `DT_ENVIRONMENT_NAME` | environmentName in Additional Information |
| 718 | `DEFAULT_SET_ASSIGNED_TO` | Optional assignee for the default set |
| 720 to 725 | `ENV_VALUE` | Environment label to stored value |

### Main function (728 to 863)

| Lines | Block | What it does |
|---|---|---|
| 729 to 734 | Read tasks 1 and 2 | `e`, `s`, `a` (alert), `req` (snow_required), `en` (enrichment) |
| 736 to 738 | `missing` | Group name missing; service and CI both missing |
| 739 | `skip` | Maintenance and SKIP_WHEN_MAINTENANCE |
| 741 to 743 | Helpers | `prop` reads an event property; `ref` prefers sys_id over name |
| 746 to 747 | Short description | Prefix, CI fqdn or name or host, event name; max 160 characters |
| 750 to 759 | `additional` | Additional Information JSON (INC30340215 layout) |
| 761 | `envLabel` | Environment label, else the offering environment |
| 762 to 780 | `snowIncident` | The body that task 4 POSTs; `undefined` fields are dropped when converted to JSON |
| 783 to 803 | `formCheck` | One row per form field: label, field, mandatory, first line of value, status |
| 804 | Add MISSING rows | Mandatory empty fields go into `missing` |
| 805 | `readyForSnow` | True when nothing is missing |
| 807 to 832 | `pagerduty` | Trigger body; routing key is a placeholder, task 5 fills it |
| 834 to 859 | `output` | Everything together, including `decision` |
| 839 to 843 | `decision` | `create_incident` and the reason text |
| 861 | `console.log` | Prints the output in the task log |
| 862 | `return output` | Task result |

## TASK 4 — lines 865 to 956

| Lines | Code idea | What it does |
|---|---|---|
| 865 to 878 | Frame | Id `post-silva-incident`, row 4, after `display-result` if OK |
| 883 to 885 | SILVA settings | URL, user, password (secret on 885) |
| 886 | `DRY_RUN` | true means never POST |
| 887 | `ALLOW_SAMPLE_POST` | false means manual Run never creates a ticket |
| 890 to 894 | `headers` | Auth, accept JSON, send JSON |
| 898 | Read task 3 | `r` |
| 899 | `body` | Copy of the SNOW body (JSON round trip removes `undefined` fields) |
| 902 to 904 | Decision check | Not allowed: `skipped` with the reason |
| 905 to 907 | Sample check | Sample event: `skipped` |
| 910 to 915 | Duplicate check | GET incident with the same correlation_id and active=true |
| 916 to 924 | Existing incident | Return `exists` with its number |
| 926 to 929 | Dry run | Log the body, return `dry_run` |
| 931 to 935 | POST | Create the incident |
| 936 to 941 | Error handling | Non-2xx: throw, so the task shows failed |
| 942 to 953 | `out` | Number, sys_id, state, group, service, offering, link |
| 954 to 955 | Log and return | Task result |

## TASK 5 — lines 958 to 1020

| Lines | Code idea | What it does |
|---|---|---|
| 958 to 971 | Frame | Id `trigger-pagerduty`, row 5, after `post-silva-incident` if OK |
| 976 | `ROUTING_KEY` | PagerDuty integration key (secret) |
| 977 | `DRY_RUN` | true means never send |
| 978 | `SEND_WHEN_INCIDENT_EXISTS` | false means no second page for an open incident |
| 983 to 984 | Read tasks 3 and 4 | `r` and `inc` |
| 986 to 988 | SILVA skipped | Return `skipped` |
| 989 to 991 | Incident existed | Return `skipped` |
| 993 | `event` | Copy of the PagerDuty body from task 3 |
| 994 to 997 | Fill in | Routing key, SILVA number, SILVA link, link button |
| 999 to 1001 | Dry run | Return the body with the key hidden |
| 1003 to 1007 | POST | Send to PagerDuty Events API v2 |
| 1008 to 1011 | Error handling | Non-2xx: throw |
| 1014 to 1019 | Return | `triggered`, PagerDuty status, dedup_key, SILVA number |

---

# Part 2 — CLOSE workflow (`11-v6-close-silva-pagerduty.workflow.yaml`)

## Lines 1 to 22 — header comments

| Lines | What they say |
|---|---|
| 1 | Name and path: problem closed, resolve SILVA, resolve PagerDuty |
| 2 to 4 | Pairs with OPEN v6 and uses the same two keys |
| 5 to 9 | The three tasks; PagerDuty runs in parallel with SILVA |
| 10 to 15 | Safety behaviour: not_found, already_resolved, sample guard, dry run |
| 16 to 20 | Checklist before activating |

## Lines 22 to 55 — metadata, identity and trigger

| Lines | Code | Meaning |
|---|---|---|
| 22 to 28 | `metadata` | Same as OPEN |
| 30 | `title` | CLOSE v6 name |
| 31 to 34 | `description` | Short explanation |
| 35 | `schemaVersion: 3` | Same format |
| 39 to 42 | `filterQuery` | Davis problem that is CLOSED, or transition RESOLVED or CLOSED |
| 46 to 51 | `categories` | All five problem types |
| 55 | `hourlyExecutionLimit: 1000` | Safety cap |

## TASK 1 prepare-close — lines 57 to 187

| Lines | Code idea | What it does |
|---|---|---|
| 57 to 70 | Frame | Id `prepare-close`, row 1, no predecessors (runs first) |
| 70 to 72 | Imports | Same three SDK helpers as OPEN task 1 |
| 73 | `USE_PROBLEM_API` | Try the Problems API |
| 74 | `RESOLVE_COMMENT` | Customer-visible comment text |
| 75 to 86 | `SAMPLE_EVENT` | Closed version of the Oracle event, with start and end times |
| 89 | `asList` | Same as OPEN |
| 91 to 95 | `parseTag` | Same as OPEN (without the raw field) |
| 97 to 103 | `toMs(v)` | Turns a time into milliseconds: number, nanoseconds, digits string, or ISO date |
| 105 to 109 | `duration(ms)` | "25 min" or "1 h 5 min" |
| 112 to 116 | Event | Real event or sample; tenant URL |
| 118 to 127 | Problems API | Same pattern as OPEN |
| 129 | `problemId` | `display_id`, the same key OPEN used |
| 130 to 131 | `problemUrl` | Link to the problem |
| 133 to 134 | `tags` and `tag()` | Parsed tags and a finder |
| 135 | `host` | Host tag or `host.name` |
| 136 to 138 | `entity` | Root cause, affected name, entity field, host |
| 139 | `group` | Any assignment or support group tag (notes only) |
| 141 to 144 | Times | Start, end (now if missing), duration |
| 145 | `title` | Event name |
| 146 to 147 | `evidence` | Up to three root-cause evidence lines |
| 149 to 157 | `closeNotes` | Short resolution text; empty lines removed; max 3900 characters |
| 159 to 170 | `workNotes` | Detailed internal text |
| 172 to 186 | `return {...}` | Keys (`correlationId`, `dedupKey`), notes, entity, host, duration |

## TASK 2 resolve-silva-incident — lines 189 to 291

| Lines | Code idea | What it does |
|---|---|---|
| 189 to 204 | Frame | Row 2, after `prepare-close` if OK |
| 207 to 209 | SILVA settings | URL, user, password (secret on 209) |
| 210 | `DRY_RUN` | Build only |
| 211 | `ALLOW_SAMPLE_SEND` | Manual Run sends nothing when false |
| 212 | `RESOLVED_STATE` | "6" means Resolved |
| 213 | `CLOSE_CODE` | Resolution code |
| 214 | `EXTRA_RESOLVE_FIELDS` | Extra fields if SILVA requires them |
| 217 to 221 | `headers` | Auth and JSON |
| 223 to 228 | `getJson(url)` | GET that throws on error (so a SILVA outage shows red) |
| 232 | Read task 1 | `p` |
| 234 to 236 | Sample guard | `skipped` |
| 238 | `fields` | Columns plus `display_value=all` (value and name for each field) |
| 239 to 241 | Open incident | GET correlation_id, active=true, newest first |
| 243 to 256 | Not open | GET any incident with that key: `already_resolved`, else `not_found` |
| 258 to 259 | `sysId`, `number` | From the open incident |
| 260 to 266 | `body` | state, close_code, close_notes, comments, work_notes, plus extras |
| 268 to 270 | Dry run | Return the body |
| 272 to 276 | PATCH | Update only these fields on the incident |
| 277 to 278 | Error handling | Non-2xx: throw with the SILVA message |
| 282 to 290 | Return | `resolved`, number, sys_id, state, close_code, link |

## TASK 3 resolve-pagerduty — lines 293 to 343

| Lines | Code idea | What it does |
|---|---|---|
| 293 to 308 | Frame | Position x 1 y 2 (next to task 2); predecessor is `prepare-close`, so it runs in parallel with task 2 |
| 311 | `ROUTING_KEY` | Same key as OPEN (secret) |
| 312 to 313 | `DRY_RUN`, `ALLOW_SAMPLE_SEND` | Same meaning as task 2 |
| 318 to 324 | `event` | routing_key, event_action "resolve", dedup_key |
| 326 to 328 | Sample guard | `skipped` |
| 329 to 331 | Dry run | Key hidden |
| 333 to 337 | POST | PagerDuty Events API v2 |
| 339 | Error handling | Non-2xx: throw |
| 342 | Return | `resolved`, status, dedup_key |

---

## How data moves between tasks

```
OPEN
 task 1 return ──► ex.result("extract-event-tags")  read by task 2 and task 3
 task 2 return ──► ex.result("resolve-snow-values") read by task 3
 task 3 return ──► ex.result("display-result")      read by task 4 and task 5
 task 4 return ──► ex.result("post-silva-incident") read by task 5

CLOSE
 task 1 return ──► ex.result("prepare-close")       read by task 2 and task 3
```

## Common YAML symbols

| Symbol | Meaning |
|---|---|
| `#` | Comment |
| `key: value` | A setting |
| Indentation | Shows which block a line belongs to (spaces, never tabs) |
| `- item` | A list item |
| `>-` | Fold the next lines into one line |
| `\|` | Keep the next lines exactly (used for scripts) |
| `{}` | Empty object |
| `[]` | Empty list |

## Data flow

```
OPEN:  event ─► 1 extract ─► 2 SILVA GET ─► 3 build ─► 4 SILVA POST ─► 5 PagerDuty trigger
CLOSE: event ─► 1 prepare ─┬► 2 SILVA GET + PATCH
                           └► 3 PagerDuty resolve
Keys:  correlation_id = display_id    dedup_key = dt-problem-<display_id>
```

## Related files

| File | What it is |
|---|---|
| `../9-v6-full-open-silva-pagerduty/9-v6-full-open-silva-pagerduty.workflow.yaml` | OPEN workflow |
| `../11-v6-close-silva-pagerduty/11-v6-close-silva-pagerduty.workflow.yaml` | CLOSE workflow |
| `../10-v6-entire-logic-flow-explained/` | Logic view (by decision, not by line) |
| `12.sh` | Commands to view the line ranges |

## Commands

See `12.sh`.
