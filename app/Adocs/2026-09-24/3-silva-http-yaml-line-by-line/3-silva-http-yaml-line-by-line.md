# Silva Http Yaml Line By Line

```
How to read this guide
  → OPEN file first (lines 1–269)
  → CLOSE file second (lines 1–206)
  → "# …" = comment for humans (Dynatrace ignores)
  → nested indent = child of the line above
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| OPEN | 269 lines — prepare → SILVA create + PD trigger |
| CLOSE | 206 lines — prepare → SILVA resolve + PD resolve |
| Sync | `correlationId = problemId`, `dedupKey = dt-problem-<id>` |
| Replace | `__SNOW_PASSWORD__`, `__PD_ROUTING_KEY__` in both |

## Summary

Line-by-line meaning of both workflow YAMLs. Comments teach; `metadata` / `workflow` / `tasks` are what Dynatrace imports. JavaScript inside `script: |` is the HTTP logic.

## Investigation

User asked for line-by-line explain of `1-open-…yaml` and `2-close-…yaml` from seq 1.

## Result

Use tables below while scrolling the YAML. Keep OPEN + CLOSE both Active after replacing secrets.

---

# FILE 1 — OPEN (`1-open-silva-http-and-pagerduty.workflow.yaml`)

## Lines 1–12 — header comments (not executed)

| Line | Text (short) | What it means |
| --- | --- | --- |
| 1 | `# OPEN — Problem ACTIVE → …` | This file is the OPEN workflow |
| 2 | `# Situation: cannot use … snow-*` | Why we use JS HTTP instead of connector |
| 3 | `# SILVA / SNOW instance example` | Target host URL |
| 4–6 | `# Sync keys` | How SNOW and PD stay linked |
| 7–11 | `# BEFORE ACTIVATE` | Checklist: allowlist, secrets, ITSM OFF, CMDB skip |
| 12 | `#` | Blank comment separator |

## Lines 13–19 — metadata

| Line | Text | What it means |
| --- | --- | --- |
| 13 | `metadata:` | Package header for the workflow file |
| 14 | `version: "1"` | File metadata version |
| 15–16 | `dependencies:` / `apps:` | Apps this workflow needs |
| 17–18 | `id: dynatrace.automations` / `version: ^1.3301.5` | Automations app (provides `run-javascript`) |
| 19 | `inputs: []` | No extra workflow-level input parameters |

## Lines 20–44 — workflow shell + trigger

| Line | Text | What it means |
| --- | --- | --- |
| 20 | `workflow:` | Start of the real workflow object |
| 21 | `title: AGO - Problem OPEN …` | Name shown in Dynatrace UI |
| 22–24 | `description: >-` + 2 lines | Folded multi-line description (no connector; parallel HTTP; sync) |
| 25 | `schemaVersion: 3` | Workflow schema format version |
| 26–27 | `trigger:` / `eventTrigger:` | Starts from an event (not cron) |
| 28 | `isActive: true` | Trigger enabled when workflow is Active |
| 29–32 | `filterQuery: >-` + conditions | Only Davis Problems that are ACTIVE and CREATED/UPDATED/REOPENED |
| 33–34 | `triggerConfiguration:` / `type: davis-problem` | Problem-type trigger |
| 35–40 | `value:` / `categories:` all `true` | Listen to error, resource, slowdown, availability |
| 41 | `entityTags: {}` | No entity-tag filter (all matching problems) |
| 42 | `type: STANDARD` | Normal workflow type |
| 43 | `input: {}` | Empty workflow input map |
| 44 | `hourlyExecutionLimit: 1000` | Safety cap: max 1000 runs per hour |
| 45 | `tasks:` | Task list starts |

## Lines 46–54 — task `prepare-payload` shell

| Line | Text | What it means |
| --- | --- | --- |
| 46 | `prepare-payload:` | Task id (key used by later `ex.result(...)`) |
| 47 | `name: prepare-payload` | Display name |
| 48 | `description: Build shared fields…` | What this task is for |
| 49 | `action: dynatrace.automations:run-javascript` | Run JS task |
| 50 | `active: true` | Task is enabled |
| 51–53 | `position: x:0 y:1` | Canvas: top/left |
| 54 | `predecessors: []` | First task — no dependency |
| 55–56 | `input:` / `script: \|` | Literal block: JS source follows |

## Lines 57–124 — `prepare-payload` JavaScript

| Line | Text | What it means |
| --- | --- | --- |
| 57 | `import { execution } …` | SDK helper to read this run |
| 59 | `export default async function ({ executionId })` | Entry point Dynatrace calls |
| 60 | `const ex = await execution(executionId)` | Load this execution |
| 61 | `const ev = ex.event() \|\| {}` | Problem event payload (or empty object) |
| 63–67 | `problemTitle = … \|\| "Dynatrace Problem"` | Title with fallbacks |
| 68–73 | `problemId = … \|\| "unknown-problem"` | Sync root id with fallbacks |
| 74–78 | `problemUrl = … \|\| ""` | Deep-link URL |
| 79–84 | `severity = String(…).toUpperCase()` | Severity string, uppercased |
| 85–89 | `hostName = … \|\| ""` | Host name if present |
| 91–93 | default `pdSeverity` / impact / urgency | Start mild: warning / 3 / 3 |
| 94–97 | if AVAILABILITY or CRITICAL | Hottest mapping |
| 98–101 | else if ERROR | Medium mapping |
| 104–105 | `notificationDescription = "[OPEN] …"` | Human-readable ticket text |
| 107–123 | `return { … }` | Object later tasks read |
| 108–117 | problem fields + mapped severities | Shared content |
| 118–120 | `correlationId` / `dedupKey` | **Sync keys** (must match CLOSE) |
| 121–122 | `silvaBaseUrl` / `silvaUsername` | SILVA target + user |
| 124 | `}` | End function |

## Lines 126–140 — task `post-silva-incident-http` shell

| Line | Text | What it means |
| --- | --- | --- |
| 126 | `post-silva-incident-http:` | Task id for SILVA create |
| 127 | `name: …` | Display name |
| 128–129 | `description: >-` | HTTP POST; CMDB may skip |
| 130 | `action: …run-javascript` | JS again |
| 131 | `active: true` | Enabled |
| 132–134 | `position: x:0 y:2` | Below prepare, left column |
| 135–136 | `predecessors: - prepare-payload` | Wait for prepare |
| 137–139 | `conditions: prepare-payload: OK` | Only run if prepare succeeded |
| 140–141 | `input:` / `script: \|` | JS block starts |

## Lines 142–204 — SILVA create JavaScript

| Line | Text | What it means |
| --- | --- | --- |
| 142 | `import { execution } …` | Same SDK import |
| 144–147 | `basicAuthHeader(user, pass)` | Build `Basic …` header (Base64 user:pass) |
| 149 | `export default async function …` | Task entry |
| 150–151 | `ex` + `p = await ex.result("prepare-payload")` | Reuse prepare output |
| 153 | `baseUrl = …replace(/\/$/, "")` | SILVA URL, strip trailing slash |
| 154 | `username = …` | SNOW user |
| 155 | `password = "__SNOW_PASSWORD__"` | **Replace before Activate** |
| 156–160 | `headers = { Authorization, Content-Type, Accept }` | REST headers |
| 162 | comment about Table API / sync field | Reminder for CLOSE search |
| 163–176 | `body = { … }` | Incident fields to create |
| 164–165 | short_description / description | Title + long text |
| 166 | `correlation_id: p.correlationId` | **Sync field for CLOSE** |
| 167–168 | impact / urgency | From prepare mapping |
| 169 | `caller_id: username` | Who opened the INC |
| 170 | `u_host: p.hostName` | Custom host field (if instance has it) |
| 171–175 | `work_notes: …` | Audit note with sync keys + URL |
| 178–182 | `fetch(…/incident, POST)` | Create INC over HTTP |
| 183–185 | read body; parse JSON or keep raw | Handle non-JSON errors |
| 187–193 | `if (!res.ok) throw …` | Fail loud; hint allowlist |
| 195 | `row = json.result \|\| json` | SNOW wraps result often |
| 196–203 | `return { created, number, sysId, keys, raw }` | Pass ids upward |
| 204 | `}` | End function |

## Lines 206–269 — task `trigger-pagerduty`

| Line | Text | What it means |
| --- | --- | --- |
| 206 | `trigger-pagerduty:` | Task id for PD trigger |
| 207–208 | name / description | Parallel PD trigger |
| 209–210 | action / active | JS enabled |
| 211–213 | `position: x:1 y:2` | **Right** of SILVA = parallel |
| 214–218 | predecessors + conditions | Same: after prepare OK |
| 220–221 | script start + import | |
| 223–225 | entry; load prepare result | |
| 226 | `routingKey = "__PD_ROUTING_KEY__"` | **Replace before Activate** |
| 228–247 | `body = { … }` | Events API v2 trigger payload |
| 229 | `routing_key` | Which PD Service integration |
| 230 | `event_action: "trigger"` | Open / page |
| 231 | `dedup_key: p.dedupKey` | **Sync key for CLOSE resolve** |
| 232–233 | client / client_url | Dynatrace + problem URL |
| 234–246 | `payload` + `custom_details` | Summary, severity, problem_url, correlation id |
| 249–253 | `fetch(…/v2/enqueue, POST)` | Send to PagerDuty |
| 254–256 | parse response | |
| 257–262 | `if (!res.ok) throw …` | Fail + allowlist hint |
| 263–268 | return status + keys + raw | |
| 269 | `}` | End (file ends) |

---

# FILE 2 — CLOSE (`2-close-silva-http-and-pagerduty.workflow.yaml`)

## Lines 1–6 — header comments

| Line | Text | What it means |
| --- | --- | --- |
| 1 | `# CLOSE — Problem CLOSED → …` | This file is the CLOSE workflow |
| 2 | `# No ServiceNow connector… FIND INC…` | Resolve by correlation_id |
| 3 | `# PD resolve uses dedup_key…` | Same key formula as OPEN |
| 4 | `# BEFORE ACTIVATE: same secrets` | Must match OPEN placeholders |
| 5 | `# Allowlist: …` | Same two hosts |
| 6 | `#` | Separator |

## Lines 7–38 — metadata + trigger (close variant)

| Line | Text | What it means |
| --- | --- | --- |
| 7–13 | `metadata` block | Same Automations dependency as OPEN |
| 14–18 | `workflow` title + description | CLOSE purpose text |
| 19 | `schemaVersion: 3` | Same schema |
| 20–22 | eventTrigger active | Event-driven |
| 23–26 | `filterQuery` CLOSED / RESOLVED | **Different from OPEN** — only close events |
| 27–35 | davis-problem + same categories | Same problem categories |
| 36–38 | STANDARD / input / hourly limit | Same shell as OPEN |
| 39 | `tasks:` | Tasks start |

## Lines 40–48 — task `prepare-close-ids` shell

| Line | Text | What it means |
| --- | --- | --- |
| 40–42 | id / name / description | Build same sync keys |
| 43–44 | run-javascript / active | |
| 45–47 | position x0 y1 | First canvas row |
| 48 | `predecessors: []` | First task |
| 49–50 | script block | |

## Lines 51–77 — `prepare-close-ids` JavaScript

| Line | Text | What it means |
| --- | --- | --- |
| 51 | import execution | |
| 53–55 | entry; load event | |
| 56–61 | `problemId` with fallbacks | Same root id as OPEN |
| 62–66 | `problemUrl` | For close notes |
| 67–76 | `return { … }` | |
| 68–69 | problemId / problemUrl | |
| 70–71 | `correlationId` / `dedupKey` | **Must match OPEN formulas** |
| 72–73 | `closeNotes` | Text written on SNOW resolve |
| 74–75 | silvaBaseUrl / username | Same STG target |
| 77 | `}` | End |

## Lines 79–92 — task `resolve-silva-incident-http` shell

| Line | Text | What it means |
| --- | --- | --- |
| 79–81 | id / name / description | GET then PATCH resolve |
| 82–83 | action / active | |
| 84–86 | position x0 y2 | Left column under prepare |
| 87–91 | predecessors + conditions | After prepare-close-ids OK |
| 92–93 | script | |

## Lines 94–165 — SILVA resolve JavaScript

| Line | Text | What it means |
| --- | --- | --- |
| 94–99 | import + basicAuthHeader | Same auth helper as OPEN |
| 101–103 | entry; `p = result("prepare-close-ids")` | |
| 105–112 | baseUrl / user / password / headers | Same as OPEN create |
| 114 | `q = encodeURIComponent("correlation_id=" + …)` | Safe query string |
| 115–119 | `searchUrl = …sysparm_query…limit=1…fields=…` | Find one INC by sync field |
| 121–124 | GET fetch; parse JSON | Search call |
| 125–130 | if search not ok → throw | Hard fail on search HTTP error |
| 132 | `rows = searchJson.result \|\| []` | List of matches |
| 133–140 | if no rows → soft return `found: false` | **Do not fail** if SILVA skipped create |
| 142 | `row = rows[0]` | First match |
| 143–147 | `patchBody` state 6 + close_code + notes | SNOW Resolved |
| 148–152 | PATCH `/incident/{sys_id}` | Apply resolve |
| 153–156 | if patch not ok → throw | |
| 158–164 | return found true + number/sysId/keys | |
| 165 | `}` | End |

## Lines 167–206 — task `resolve-pagerduty`

| Line | Text | What it means |
| --- | --- | --- |
| 167–169 | id / name / description | PD resolve with same dedup_key |
| 170–171 | action / active | |
| 172–174 | position x1 y2 | Right = parallel with SILVA |
| 175–179 | predecessors + conditions | After prepare OK |
| 181–182 | script + import | |
| 184–187 | entry; load prepare; routing key placeholder | |
| 189–197 | `fetch` enqueue with `event_action: "resolve"` | Clear the page |
| 193–195 | routing_key / resolve / dedup_key | Only what PD needs to match OPEN |
| 198–204 | read text; throw if not ok; allowlist hint | |
| 205 | `return { dedupKey, correlationId, raw }` | |
| 206 | `}` | End of file |

---

## Cross-file line map (sync)

| Concept | OPEN lines | CLOSE lines |
| --- | --- | --- |
| Set/reuse `correlationId` | 119, 166, 200 | 70, 114, 137, 162 |
| Set/reuse `dedupKey` | 120, 231, 201 | 71, 195, 163, 205 |
| Password placeholder | 155 | 107 |
| PD routing key placeholder | 226 | 187 |
| Parallel canvas (x=1,y=2) | 211–213 | 172–174 |

---

## Data flow map

```
OPEN L46–124 prepare → L126–204 SILVA POST + L206–269 PD trigger
CLOSE L40–77 prepare → L79–165 SILVA GET/PATCH + L167–206 PD resolve
```

---

## Related files

| File | Role |
| --- | --- |
| `../1-silva-http-snow-pd-sync-workflows/1-open-….yaml` | OPEN source |
| `../1-silva-http-snow-pd-sync-workflows/2-close-….yaml` | CLOSE source |
| `../2-silva-http-yaml-details-explain/` | Task-level explain (not line-by-line) |
| `3.sh` | Optional helpers (user runs) |

## Commands

See `3.sh`.
