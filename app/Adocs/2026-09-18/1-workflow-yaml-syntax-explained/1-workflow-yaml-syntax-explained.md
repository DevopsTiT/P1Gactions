# Workflow Yaml Syntax Explained

```
Need to read / edit Dynatrace Workflow YAML?
  │
  ├─ Learn plain YAML rules (indent, keys, strings, |)
  ├─ Learn workflow schema blocks (metadata, trigger, tasks)
  └─ Learn Dynatrace extras (Jinja result(), predecessors, connectionId)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| YAML | Indentation-based data format (spaces, not tabs) |
| This file type | Dynatrace Workflow definition (`schemaVersion: 3`) |
| Hardest parts | Multi-line JS under `script: \|`, Jinja `{{ result(...) }}`, task graph |
| Example files | Seq 22 OPEN/CLOSE under `2026-09-17/22-yaml-with-all-example-data/` |

## Summary

Workflow YAML is normal YAML plus a Dynatrace schema. Below: YAML syntax rules, then every important key in your OPEN/CLOSE workflows, with tiny examples.

---

## Investigation

User asked for YAML syntax and related details for the latest Dynatrace workflow YAML. Explained general YAML + Dynatrace Workflow schema using seq 22 as the reference shape.

## Result

Use §1–§3 for YAML literacy, §4–§8 for workflow-specific syntax, §9 for common edit mistakes.

---

## 1) What YAML is (plain English)

| Idea | What it means | Why you care |
| --- | --- | --- |
| YAML | Human-readable structured text | Workflows are uploaded as this format |
| Key / value | `title: My Workflow` | Most settings are key-value pairs |
| Nesting | Indent under a parent key | Wrong indent = broken or wrong meaning |
| List | Lines starting with `- ` | Apps, predecessors, categories |
| Comment | Line starting with `#` | Notes; Dynatrace ignores them |

Dynatrace does **not** run comments. Comments are for humans only.

---

## 2) Core YAML syntax rules

### Indentation (most important)

| Rule | Example |
| --- | --- |
| Use **spaces** (usually 2) | never tabs |
| Child is indented more than parent | see below |
| Same level = same indent | siblings align |

```yaml
workflow:
  title: AGO - Example
  tasks:
    prepare-payload:
      name: prepare-payload
```

| Bad | Why |
| --- | --- |
| Mixing tabs and spaces | Parsers fail or mis-nest |
| Random indent under `tasks` | Task not recognized |

### Scalars (single values)

| Type | Syntax | Example |
| --- | --- | --- |
| Unquoted string | fine if no special chars | `name: prepare-payload` |
| Quoted string | when unsure / special chars | `title: "AGO - Problem to SNOW+PD"` |
| Number | bare | `hourlyExecutionLimit: 1000` |
| Boolean | `true` / `false` | `active: true` |
| Empty string | `""` | `connectionId: ""` |
| Null-ish empty map | `{}` | `entityTags: {}` |
| Empty list | `[]` | `predecessors: []` |

### Lists

```yaml
predecessors:
  - prepare-payload
  - create-servicenow-incident
```

Same as:

```yaml
predecessors: [prepare-payload, create-servicenow-incident]
```

Your files use the dash style (clearer).

### Nested maps (objects)

```yaml
group:
  id: '{{ result("prepare-payload").assignmentGroupSysId }}'
  displayName: '{{ result("prepare-payload").assignmentGroupName }}'
```

`group` has two child keys: `id` and `displayName`.

### Multi-line strings — `|` vs `>`

| Operator | Meaning | Used for |
| --- | --- | --- |
| `\|` (literal block) | Keep newlines | JavaScript `script:`, long comments |
| `>` (folded) | Join lines with spaces | Long `description:` text |

**Your OPEN file uses both:**

```yaml
description: >-
  EXAMPLE DATA pack. On Problem open, ...
```

```yaml
script: |
  import { execution } from '@dynatrace-sdk/automation-utils';
  export default async function ({ executionId }) {
    ...
  }
```

| Detail | Meaning |
| --- | --- |
| `>-` | Folded, strip final newline |
| `\|` | Keep exact line breaks inside the script |

Everything indented under `script: |` is **one string** (the JS source). One wrong un-indent can end the string early and break YAML.

### Quotes inside strings

Jinja in your YAML often needs quotes inside quotes:

```yaml
correlationId: '{{ result("prepare-payload").problemId }}'
```

| Pattern | Meaning |
| --- | --- |
| Outer `'` | YAML single-quoted string |
| Inner `"prepare-payload"` | JS/Jinja string for task name |

Do not write:

```yaml
correlationId: {{ result("prepare-payload").problemId }}
```

without quotes — `{` can confuse YAML.

### Comments

```yaml
# This is a comment
active: true   # end-of-line comment also OK
```

---

## 3) Overall document shape (Dynatrace Workflow)

Top-level structure of your files:

```yaml
# comments...
metadata:
  version: "1"
  dependencies: ...
  inputs: ...
workflow:
  title: ...
  description: ...
  schemaVersion: 3
  trigger: ...
  type: STANDARD
  input: {}
  hourlyExecutionLimit: 1000
  tasks:
    task-name:
      ...
```

| Top key | Required role |
| --- | --- |
| `metadata` | Apps + Connection input bindings |
| `workflow` | The actual automation definition |

There is **no** other root key in your pack.

---

## 4) `metadata` block syntax

```yaml
metadata:
  version: "1"
  dependencies:
    apps:
      - id: dynatrace.automations
        version: ^1.3301.5
      - id: dynatrace.servicenow
        version: ^2.1.0
  inputs:
    - type: connection
      schema: app:dynatrace.servicenow:connection
      targets:
        - tasks.create-servicenow-incident.connectionId
        - tasks.cross-link-snow-pd.connectionId
```

| Key | Syntax meaning |
| --- | --- |
| `dependencies.apps` | List of `{id, version}` maps |
| `version: ^1.3301.5` | Semver range string (caret = compatible) |
| `inputs` | List of input declarations |
| `type: connection` | This input is a Connection picker |
| `schema:` | Which Connection type (ServiceNow) |
| `targets:` | List of **dotted paths** into task fields to fill |

**Target path syntax:** `tasks.<taskKey>.connectionId`

| Piece | Meaning |
| --- | --- |
| `tasks` | Under workflow.tasks |
| `create-servicenow-incident` | Task key (must match) |
| `connectionId` | Field left `""` in YAML for UI mapping |

CLOSE file targets `search-snow-incident` and `resolve-snow-incident` instead.

---

## 5) `workflow` identity fields

```yaml
workflow:
  title: AGO - Problem to SNOW+PD (EXAMPLE DATA FILLED)
  description: >-
    EXAMPLE DATA pack. ...
  schemaVersion: 3
  type: STANDARD
  input: {}
  hourlyExecutionLimit: 1000
```

| Key | Type | Meaning |
| --- | --- | --- |
| `title` | string | Display name |
| `description` | folded multi-line string | Longer blurb |
| `schemaVersion` | number | Format version (`3`) |
| `type` | string | `STANDARD` workflow |
| `input` | map | Workflow-level inputs (`{}` = none) |
| `hourlyExecutionLimit` | number | Max executions per hour |

---

## 6) `trigger` block syntax

### OPEN shape

```yaml
trigger:
  eventTrigger:
    isActive: true
    filterQuery: >-
      event.kind == "DAVIS_PROBLEM" AND event.status == "ACTIVE" AND
      (event.status_transition == "CREATED" OR ...)
    triggerConfiguration:
      type: davis-problem
      value:
        categories:
          error: true
          resource: true
          slowdown: true
          availability: true
        entityTags: {}
```

| Key | Meaning |
| --- | --- |
| `eventTrigger` | Event-driven (not schedule) |
| `isActive` | Trigger enabled |
| `filterQuery` | DQL-like boolean filter string (folded with `>-`) |
| `triggerConfiguration.type` | `davis-problem` |
| `value.categories` | Map of category name → boolean |
| `entityTags: {}` | Empty map = no tag filter on trigger |

### CLOSE differences

Same structure; `filterQuery` checks CLOSED / RESOLVED instead of ACTIVE + CREATED.

### `filterQuery` string tips

| Syntax in query | Meaning |
| --- | --- |
| `==` | equals |
| `AND` / `OR` | boolean |
| `"DAVIS_PROBLEM"` | string literal inside the query |
| Line breaks via `>-` | Still one logical query string |

This is **not** YAML boolean logic — it is one string Dynatrace parses later.

---

## 7) `tasks` block syntax

### Task key vs `name`

```yaml
tasks:
  prepare-payload:          # ← key (id used in predecessors / result())
    name: prepare-payload   # ← display name (usually same)
    description: ...
    action: dynatrace.automations:run-javascript
    active: true
    position:
      x: 0
      y: 1
    predecessors: []
    conditions:
      states:
        prepare-payload: OK
    input:
      ...
```

| Field | Meaning |
| --- | --- |
| Task **key** | Map key under `tasks` — must match `result("...")` and predecessors |
| `name` | UI label |
| `description` | Human text |
| `action` | What runs (`app:action-id`) |
| `active` | Task enabled |
| `position.x` / `y` | Canvas layout (integers; `y` starts at 1 in your pack) |
| `predecessors` | List of task keys that must finish first |
| `conditions` | When this task may run |
| `input` | Action-specific parameters |

### `action` string format

| Example | Meaning |
| --- | --- |
| `dynatrace.automations:run-javascript` | Built-in JS runner |
| `dynatrace.servicenow:snow-create-incident` | ServiceNow Connector create |
| `dynatrace.servicenow:snow-comment-on-incident` | Comment |
| `dynatrace.servicenow:snow-search-incidents` | Search |
| `dynatrace.servicenow:snow-resolve-incident` | Resolve |

Pattern: `<app-id>:<action-id>`

### `predecessors`

```yaml
predecessors:
  - prepare-payload
```

```yaml
predecessors:
  - create-servicenow-incident
  - create-pagerduty-incident
```

| Case | Meaning |
| --- | --- |
| `[]` | Start immediately (first task) |
| One item | Wait for that task |
| Two items | Wait for **both** (cross-link) |

Parallelism: two tasks with the **same** predecessor run side by side (SNOW create ‖ PD create).

### `conditions`

```yaml
conditions:
  states:
    prepare-payload: OK
```

| Meaning | Run only if listed predecessor ended OK |

CLOSE resolve adds custom Jinja:

```yaml
conditions:
  states:
    search-snow-incident: OK
  custom: '{{ result("search-snow-incident") | length > 0 }}'
  else: SKIP
```

| Key | Meaning |
| --- | --- |
| `custom` | Extra boolean expression |
| `else: SKIP` | If custom false, skip task (do not fail workflow) |
| `\| length > 0` | Jinja-style filter: list not empty |

### `position`

```yaml
position:
  x: 0
  y: 2
```

| Use | UI canvas only — does not change logic |
| --- | --- |
| Your convention | `y: 1` first row; parallel tasks share `y`, different `x` |

---

## 8) `input` syntax by action type

### A) JavaScript task

```yaml
input:
  script: |
    import { execution } from '@dynatrace-sdk/automation-utils';
    export default async function ({ executionId }) {
      ...
      return { problemId, dedupKey };
    }
```

| Rule | Detail |
| --- | --- |
| Only key needed | `script` (string) |
| Language | JavaScript (not YAML) **inside** the string |
| Return object | Becomes `result("task-name")` for later tasks |

### B) snow-create-incident

```yaml
input:
  connectionId: ""
  correlationId: '{{ result("prepare-payload").problemId }}'
  caller: '{{ result("prepare-payload").caller }}'
  category: '{{ result("prepare-payload").category }}'
  subCategory: '{{ result("prepare-payload").subcategory }}'
  impact: '{{ result("prepare-payload").impact }}'
  urgency: '{{ result("prepare-payload").urgency }}'
  group:
    id: '...'
    displayName: '...'
  shortDescription: '...'
  description: '...'
```

| Syntax note | Detail |
| --- | --- |
| Flat keys | Most fields are strings |
| Nested `group` | Map with `id` + `displayName` |
| All dynamic values | Jinja `{{ ... }}` strings |

### C) snow-comment-on-incident

```yaml
input:
  connectionId: ""
  number: '{{ result("create-servicenow-incident").number }}'
  comment: |
    PagerDuty sync: dedup_key={{ result("create-pagerduty-incident").dedupKey }}
    | Dynatrace Problem={{ result("prepare-payload").problemUrl }}
```

| Note | `comment: \|` can mix literal text and `{{ }}` placeholders |

### D) snow-search-incidents

```yaml
input:
  connectionId: ""
  sysparmQuery: 'correlation_id={{ result("prepare-close-ids").problemId }}'
  sysparmLimit: "1"
  sysparmFields: number,sys_id,correlation_id,state
```

| Note | `sysparmFields` is one comma-separated string, not a YAML list |

### E) snow-resolve-incident

```yaml
input:
  connectionId: ""
  number: '{{ result("search-snow-incident")[0].number }}'
  resolutionNotes: '{{ result("prepare-close-ids").closeNotes }}'
  resolutionCode: Solved (Permanently)
```

| Syntax | Meaning |
| --- | --- |
| `[0]` | First search hit |
| Unquoted resolutionCode | OK here (no special YAML chars) |

---

## 9) Jinja / template syntax (Dynatrace expressions)

Used inside many `input` strings:

| Expression | Meaning |
| --- | --- |
| `{{ result("prepare-payload").problemId }}` | Field from prior task return |
| `{{ result("search-snow-incident")[0].number }}` | First array element field |
| `{{ result("search-snow-incident") \| length > 0 }}` | Custom condition |
| `result("task-key")` | Task **key** must match exactly |

| Rule | Detail |
| --- | --- |
| Evaluated at runtime | Not plain YAML substitution at upload |
| Task must have succeeded | Or expression may fail |
| Quotes | Prefer wrapping whole expression in `'...'` |

---

## 10) Mini annotated OPEN snippet

```yaml
tasks:
  prepare-payload:                    # task key
    name: prepare-payload
    action: dynatrace.automations:run-javascript
    active: true
    position: { x: 0, y: 1 }          # could also be nested form
    predecessors: []                  # first task
    input:
      script: |                       # multi-line JS string starts
        export default async function ({ executionId }) {
          return { problemId: "P-1", dedupKey: "dt-problem-P-1" };
        }                             # still inside script until indent ends

  create-servicenow-incident:
    action: dynatrace.servicenow:snow-create-incident
    predecessors:
      - prepare-payload               # YAML list of one
    conditions:
      states:
        prepare-payload: OK
    input:
      connectionId: ""                # empty string
      correlationId: '{{ result("prepare-payload").problemId }}'
```

---

## 11) Common YAML edit mistakes

| Mistake | What happens |
| --- | --- |
| Tab indentation | Parse error or wrong nesting |
| Un-indenting mid-`script: \|` | JS truncated; YAML thinks new keys start |
| Renaming task key but not predecessors/`result()` | Broken wiring |
| `connectionId` deleted instead of `""` | Upload/schema issues |
| Bare `{{ ... }}` without quotes | YAML parse error |
| Changing only OPEN PD key, not CLOSE | Resolve misses alert |
| `y: 0` positions (in some DT versions) | Validation errors — your pack uses `y >= 1` |
| Forgetting space after `-` in lists | Invalid list item |

---

## 12) How to edit safely

| Step | Practice |
| --- | --- |
| 1 | Copy file; edit the copy |
| 2 | Change one thing at a time |
| 3 | Keep task keys stable |
| 4 | Validate indent in an editor with YAML mode |
| 5 | Re-upload / refresh workflow; check UI graph |
| 6 | Run a test Problem; read Executions |

---

## Data flow map (syntax → runtime)

```
YAML file
  metadata.inputs.targets  → UI Connection mapping
  workflow.trigger         → when execution starts
  workflow.tasks.*.action  → which runner
  predecessors/conditions  → order + skip rules
  input + {{ result() }}   → runtime parameters
  script: |                → JS source string
        │
        ▼
Dynatrace Workflow engine executes tasks
```

## Related files

| Path | Why |
| --- | --- |
| `../2026-09-17/22-yaml-with-all-example-data/` | Full OPEN/CLOSE YAML to read alongside |
| `../2026-09-17/34-latest-workflow-yaml-explained/` | What each task does (behavior) |
| `1.sh` | Paths |

## Commands

See `1.sh` in this folder.
