# Open And Close YAML Line By Line

Mirror of CursorFiles `Daily Files/2026-09-28/5-open-close-yaml-line-by-line/5-open-close-yaml-line-by-line.md` (full version there; same content below in condensed-table form).

## Decision tree (how to read either file)

```
Open a workflow YAML
 lines starting with #            → comments only, Dynatrace ignores them
 metadata:                        → which app versions the workflow needs
 workflow: → trigger:             → WHEN it runs (which Problem events)
 workflow: → tasks:               → WHAT it does, one block per task
    each task
     position x/y                 → where the box sits on the canvas
     predecessors                 → which task must finish first
     conditions                   → run / skip rules
     input.script                 → the JavaScript that does the real work
        export default function   → entry point, its return value = task result
        ex.result("other-task")   → read another task's result
```

## Short takeaway

| Question | Answer |
|---|---|
| What is the OPEN file? | Runs when a Dynatrace Problem opens. It enriches the data, creates a SILVA ticket and a PagerDuty page at the same time, then cross-links them. |
| What is the CLOSE file? | Runs when the Problem closes. It resolves the SILVA ticket and the PagerDuty incident at the same time. |
| How do the two files find the same ticket? | Two sync keys: `correlation_id = problemId` in SNOW, and `dedup_key = dt-problem-<problemId>` in PagerDuty. |
| Where is the logic? | Inside `script: \|` blocks. Everything under that line is JavaScript, not YAML. |
| How do tasks share data? | A task `return`s an object; later tasks read it with `ex.result("task-name")`. |

## Summary

Each file has two parts. The **YAML part** is the frame: the trigger, the task boxes, their order and their run conditions. The **JavaScript part** inside each task does the actual API calls. Line numbers match the files in `4-open-close-enriched-parallel/`.

## Part A — OPEN file

| Lines | Block | What it does |
|---|---|---|
| 1–24 | Comments | Purpose, base file, task picture, enrichment requirements, sync keys, checklist before activating. |
| 25–31 | `metadata` | Needs the Automations app `^1.3301.5`. No import inputs. |
| 32–39 | Title, description, `schemaVersion: 3` | Name and file format. `>-` folds the description into one paragraph. |
| 40–54 | `trigger` | Runs on Davis Problems that are ACTIVE and just CREATED or REOPENED. All four categories are on; no tag filter. |
| 55–57 | `type`, `input`, `hourlyExecutionLimit` | A standard workflow, capped at 1000 runs per hour to protect SILVA during alert storms. |
| 59–71 | `prepare-payload` frame | First task (x0, y1, no predecessors), runs JavaScript. `\|` keeps the script lines as written. |
| 72–75 | Imports | `execution` (run data), `problemsClient` (Problems API), `queryExecutionClient` (DQL), `getEnvironmentUrl` (tenant URL). |
| 78–80 | SILVA settings | Base URL, API user, password placeholder. |
| 82–98 | `FIELD` | Friendly name to real SNOW column. Change a column name once here. |
| 99–129 | Rule maps | Environment label, offering, keyword and severity categories, group, service and dashboard by zone or app, `DEFAULT` last-resort values. |
| 132–134 | `basicAuthHeader` | Base64 of `user:password` for the Basic auth header. |
| 135–138 | `tagValue` | Finds a tag value by key, case-insensitive. |
| 139–146 | `snowGet` | GET to SILVA; throws with an allowlist hint on failure. |
| 147–158 | `runDql` | Runs DQL and polls every second until done. |
| 160–164 | Entry point and IDs | `internalId` for the API; `problemId` (display ID) becomes the sync key. |
| 167–172 | Problem details | Title, URL, severity, impact level. |
| 174–186 | Entities and tags | Root cause, first HOST, first SERVICE, `where`, tags, zones, `env`, `app`, up to 3 evidence items. |
| 188–196 | Top error log | DQL: most common ERROR log in 30 min on that entity or host, trimmed to 250 characters. |
| 197–198 | Dashboard | Tag, then app map, then zone map. |
| 201 | `gaps` | Records every default used, so people can review. |
| 203–220 | CMDB lookup | Search by full name, short name or FQDN. Keep sys_id, retired flag (status 7), support group, business service. |
| 222–233 | Assignment group | Candidates: CI group, tag, zone map, default. First active match in `sys_user_group` wins. Throws if none. |
| 236–243 | Classification | Env, business service, offering, category. Each uses "most specific first, default last". |
| 245–249 | Impact, urgency, PagerDuty severity | SNOW works out priority from impact × urgency. Non-prod gets urgency 3. |
| 251–254 | Description text | Three lines: OPEN tag, root entity, Dynatrace link. |
| 256–290 | Return object | Everything later tasks need. **286–287 are the sync keys.** |
| 293–309 | `post-silva-incident-http` frame | x0, y2. Needs task 1 OK **and** CI not retired, otherwise SKIP. |
| 331–347 | Ticket body | `[F.caller]` uses the column name from the map as the key. The CI is added only if found. |
| 349–352 | POST incident | Send labels, get labels back, no extra link objects. |
| 353–361 | Error handling | Keeps the raw text; throws with an allowlist hint. |
| 363–380 | Return | INC number, sys_id, and `stored` — what SNOW saved, including the calculated priority. |
| 383–397 | `trigger-pagerduty` frame | x1, y2, **same parent as the SILVA task**, so both start together. Same skip rule. |
| 405–407 | Routing key and SILVA search link | The INC number isn't known yet, so it links a search by correlation ID. |
| 409–440 | Event body | trigger, dedup_key, summary, source, severity, custom_details (classification, cause, dashboard, runbook), links. |
| 442–460 | POST enqueue and return | Events API v2, routing key only. |
| 463–480 | `add-cross-links` frame | x0, y3. Waits for both posts. Needs SILVA OK; PagerDuty can be ANY. |
| 485–496 | Settings and PagerDuty headers | `comments` field (customer visible); REST key; From email; `Token token=` auth. |
| 498–509 | `findPdIncident` | Up to 6 tries, 5 seconds apart, by incident_key. |
| 513–519 | Read results and get the link | `show()` turns blanks into "NOT SET - please fill". |
| 521–552 | Notes block | Classification, cause, links, which service, dashboard, runbook, defaults used. Trimmed to 3900 characters. |
| 554–563 | PATCH comments | Writes the notes into SILVA. |
| 565–575 | PagerDuty note | INC number, priority, group and a direct SILVA link. |
| 577–578 | Return | INC, PagerDuty link, note added or not, missing fields. |

## Part B — CLOSE file

| Lines | Block | What it does |
|---|---|---|
| 1–20 | Comments | Purpose, base file, picture, what was added, sync keys, checklist and `RESOLVE_MODE`. |
| 22–35 | Metadata, title, schema | Same as OPEN. |
| 36–54 | Trigger | Runs when the Problem is CLOSED or the transition is RESOLVED or CLOSED. |
| 56–69 | `prepare-close-ids` frame and imports | First task (x0, y1). No DQL or SILVA calls. |
| 71–76 | Dashboard maps | Keep them the same as OPEN. |
| 82–86 | `duration()` | Milliseconds to "12 min" or "1 h 5 min". |
| 89–107 | Problem details | Same method as OPEN, so `problemId` matches. |
| 109–114 | Times | End time falls back to now. |
| 129–130 | **Sync keys** | Same format as OPEN. |
| 131–139 | `closeNotes` | Closed time, duration, cause, evidence, recovery statement, link, advice to raise a Problem record. |
| 145–159 | `resolve-silva-incident-http` frame | x0, y2. Needs task 1 OK. |
| 164–168 | Settings | `RESOLVE_MODE` (auto or comment-only), notes field, Resolution Type column and value, PagerDuty REST key. |
| 175–185 | `pdLink` | Includes resolved incidents and all dates. Returns empty on any error, so it never blocks the close. |
| 198–212 | Find the ticket | GET by correlation_id, newest first, `display_value=all`. |
| 214–222 | Not found | Soft stop, because OPEN may have skipped a retired CI. |
| 224–229 | Already closed | State 6, 7 or 8 means skip, so a human's close isn't overwritten. |
| 232–262 | Closing notes block | Classification at close, outcome, duration, links, which service, dashboard. |
| 264–270 | PATCH body | The note is always included. Auto mode adds state 6, close code, close notes, Resolution Type. |
| 272–286 | PATCH and verify | Throws if the state isn't 6, which catches business rules that block the change quietly. |
| 288–296 | Return | INC number, sys_id, mode, PagerDuty link, keys. |
| 299–311 | `resolve-pagerduty` frame | x1, y2, same parent, so it runs **at the same time** as the SILVA resolve. |
| 321–342 | Resolve event | `event_action: resolve`, same dedup_key, summary with duration. |

## YAML syntax cheat sheet

| Syntax | Meaning |
|---|---|
| `#` | Comment |
| Indentation | Shows what belongs to what. Use spaces only. |
| `- item` | A list item |
| `>-` | Fold the lines into one paragraph |
| `\|` | Keep the lines exactly as written |
| `{{ ... }}` | A Dynatrace expression, worked out at run time |
| `[]` and `{}` | An empty list and an empty map |

## Common mistakes

| Mistake | Result |
|---|---|
| Changing a sync key in only one file | CLOSE can't find the ticket or page. |
| Renaming a task but not its `predecessors`, `conditions` or `ex.result` | "Task not found" errors. |
| A `custom:` condition without `else: SKIP` | The task shows as failed instead of skipped. |
| Leaving the `__...__` placeholders | 401 errors. |

## Data flow map

```
OPEN:  Problem opens → prepare-payload (Problems API, DQL, CMDB, group check, rules)
                         ├─► post-silva-incident-http  (POST incident)       ┐ same time
                         └─► trigger-pagerduty         (POST enqueue)        ┘
                       → add-cross-links (PD REST link → SILVA comments; INC → PD note)

CLOSE: Problem closes → prepare-close-ids (duration, closeNotes, same keys)
                         ├─► resolve-silva-incident-http (GET by correlation_id → PATCH state 6 → verify) ┐
                         └─► resolve-pagerduty           (POST resolve, same dedup_key)                   ┘
```

## Related files

| File | What it is |
|---|---|
| `../4-open-close-enriched-parallel/1-open-silva-http-and-pagerduty-enriched.workflow.yaml` | The OPEN file |
| `../4-open-close-enriched-parallel/2-close-silva-http-and-pagerduty-enriched.workflow.yaml` | The CLOSE file |
| `5.sh` | Read-only commands to view the lines |
