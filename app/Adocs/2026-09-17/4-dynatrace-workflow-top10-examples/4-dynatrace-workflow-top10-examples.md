# Dynatrace Workflow Top10 Examples

```
Need a Dynatrace Workflow?
  │
  ├─ Learn skeleton syntax (example 1)
  ├─ Pick trigger: Problem open / close / schedule (2–4)
  ├─ Pick tasks: JS / HTTP / SNOW / PD (5–10)
  └─ Upload YAML → set secrets → Activate → test Executions
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What a Workflow is | Automation: trigger → tasks → optional notify/ticket |
| Preferred file | YAML template (`.workflow-template.yaml`) |
| Core shape | `metadata` + `workflow` (title, trigger, tasks) |
| Your CDUS/AGO style | Problem open/close + JS + optional SNOW/PD |

## Summary

A Dynatrace Workflow is a recipe: **when** something happens (trigger), **do** these steps (tasks). Below: syntax basics, then 10 copy-paste examples from skeleton to Problem→PagerDuty.

---

## Investigation

Scoped to Dynatrace **Automations / Workflows** (not classic Problem notifications alone, not DQL log alerts). Schema style matches packs that upload with `schemaVersion: 3`, `filterQuery`, and `categories` as a map.

## Result

Use the syntax section, then paste examples from this doc or `4-dynatrace-workflow-top10-examples.yaml`.

---

## 1) Workflow syntax (plain English)

| Piece | What it means |
| --- | --- |
| Trigger | When the workflow starts (Problem event, schedule, …) |
| Task | One box on the canvas (JS, HTTP, ServiceNow action, …) |
| Predecessor | “This task waits for that task” |
| Condition | Only run if prior task state is `OK` |
| Action | Built-in step type, e.g. `dynatrace.automations:run-javascript` |
| Connection | Saved credential (e.g. ServiceNow) mapped at import/UI |
| filterQuery | Extra filter on event fields |
| Allowlist | External hosts must be on Settings → External requests |

### YAML skeleton

```yaml
metadata:
  version: "1"
  dependencies:
    apps:
      - id: dynatrace.automations
        version: ^1.3301.5
  inputs: []
workflow:
  title: My workflow title
  description: What it does
  schemaVersion: 3
  type: STANDARD
  input: {}
  hourlyExecutionLimit: 1000
  trigger:
    eventTrigger:
      isActive: true
      filterQuery: 'event.kind == "DAVIS_PROBLEM"'
      triggerConfiguration:
        type: davis-problem
        value:
          categories:
            error: true
            availability: true
          entityTags: {}
  tasks:
    step-one:
      name: step-one
      action: dynatrace.automations:run-javascript
      active: true
      position:
        x: 0
        y: 1
      predecessors: []
      input:
        script: |
          export default async function () {
            return { ok: true };
          }
```

### Same idea in JSON

```json
{
  "title": "My workflow title",
  "schemaVersion": 3,
  "type": "STANDARD",
  "trigger": {
    "eventTrigger": {
      "isActive": true,
      "filterQuery": "event.kind == \"DAVIS_PROBLEM\"",
      "triggerConfiguration": {
        "type": "davis-problem",
        "value": {
          "categories": { "error": true, "availability": true },
          "entityTags": {}
        }
      }
    }
  },
  "tasks": {
    "step-one": {
      "name": "step-one",
      "action": "dynatrace.automations:run-javascript",
      "active": true,
      "position": { "x": 0, "y": 1 },
      "predecessors": [],
      "input": {
        "script": "export default async function () { return { ok: true }; }\n"
      }
    }
  }
}
```

### Rules that avoid upload Error 400

| Rule | Why |
| --- | --- |
| `position.y` ≥ 1 | Tenant rejects `y: 0` |
| `categories` is a map | Not `[]` |
| Prefer `filterQuery` for open vs close | Avoid forbidden legacy trigger fields |
| One job per workflow | Open and close as two workflows |

---

## 2) Top 10 workflow examples

### 1) Minimal “hello” workflow (syntax smoke test)

**What:** Proves upload/activate works.  
**Trigger:** Schedule every hour (or run manually if UI allows).

```yaml
metadata:
  version: "1"
  dependencies:
    apps:
      - id: dynatrace.automations
        version: ^1.3301.5
  inputs: []
workflow:
  title: Example 01 - Hello Workflow
  description: Smoke test — returns a simple object
  schemaVersion: 3
  type: STANDARD
  input: {}
  hourlyExecutionLimit: 100
  trigger:
    schedule:
      isActive: true
      rule: "0 * * * *"
      timezone: UTC
  tasks:
    hello:
      name: hello
      action: dynatrace.automations:run-javascript
      active: true
      position: { x: 0, y: 1 }
      predecessors: []
      input:
        script: |
          export default async function () {
            return { message: "hello from dynatrace workflow" };
          }
```

**Note:** Exact `schedule` shape can vary by tenant version — if upload rejects schedule, create the same JS task in UI with a Schedule trigger.

---

### 2) Problem OPEN trigger (Davis problem)

**What:** Fires when a Problem is created/updated/reopened while ACTIVE.

```yaml
trigger:
  eventTrigger:
    isActive: true
    filterQuery: >-
      event.kind == "DAVIS_PROBLEM" AND event.status == "ACTIVE" AND
      (event.status_transition == "CREATED" OR event.status_transition == "UPDATED" OR
      event.status_transition == "REOPENED")
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

---

### 3) Problem CLOSED trigger

**What:** Fires when a Problem closes/resolves (pair with open workflow).

```yaml
trigger:
  eventTrigger:
    isActive: true
    filterQuery: >-
      event.kind == "DAVIS_PROBLEM" AND
      (event.status == "CLOSED" OR event.status_transition == "RESOLVED" OR
      event.status_transition == "CLOSED")
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

---

### 4) Restrict by entity tag (prod only)

**What:** Same Problem trigger, but only tagged entities.

```yaml
triggerConfiguration:
  type: davis-problem
  value:
    categories:
      availability: true
      error: true
    entityTags:
      env: ["prod"]
```

Or tighten with `filterQuery` if your event payload exposes tags (tenant-specific). Prefer UI tag filter after import if unsure.

---

### 5) Run JavaScript — read Problem fields

**What:** First task maps event → payload for later tasks.

```yaml
tasks:
  prepare-payload:
    name: prepare-payload
    action: dynatrace.automations:run-javascript
    active: true
    position: { x: 0, y: 1 }
    predecessors: []
    input:
      script: |
        import { execution } from '@dynatrace-sdk/automation-utils';

        export default async function ({ executionId }) {
          const ex = await execution(executionId);
          const ev = ex.event() || {};
          const problemId =
            ev["display_id"] ||
            ev["problem.id"] ||
            ev["event.id"] ||
            "unknown";
          const title =
            ev["event.name"] ||
            ev["problem.title"] ||
            "Dynatrace Problem";
          return {
            problemId,
            title,
            dedupKey: "dt-problem-" + problemId,
            problemUrl: ev["problem.url"] || ev["event.url"] || ""
          };
        }
```

---

### 6) HTTP POST task pattern (via JavaScript fetch)

**What:** Call an external API (PagerDuty, webhook). Host must be allowlisted.

```yaml
tasks:
  call-webhook:
    name: call-webhook
    action: dynatrace.automations:run-javascript
    active: true
    position: { x: 0, y: 2 }
    predecessors:
      - prepare-payload
    conditions:
      states:
        prepare-payload: OK
    input:
      script: |
        import { execution } from '@dynatrace-sdk/automation-utils';

        export default async function ({ executionId }) {
          const ex = await execution(executionId);
          const p = await ex.result("prepare-payload");

          const res = await fetch("https://example.com/hooks/dynatrace", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              problem_id: p.problemId,
              title: p.title
            })
          });
          const text = await res.text();
          if (!res.ok) {
            throw new Error("HTTP " + res.status + ": " + text);
          }
          return { status: res.status, body: text };
        }
```

Allowlist: `example.com` (replace with real host).

---

### 7) Parallel tasks (two successors of prepare)

**What:** SNOW and PD at the same time after prepare.

```yaml
tasks:
  prepare-payload:
    name: prepare-payload
    # ... y: 1 ...
    predecessors: []

  create-snow:
    name: create-snow
    position: { x: 0, y: 2 }
    predecessors: [prepare-payload]
    conditions:
      states:
        prepare-payload: OK
    # action: dynatrace.servicenow:snow-create-incident ...

  create-pd:
    name: create-pd
    position: { x: 1, y: 2 }
    predecessors: [prepare-payload]
    conditions:
      states:
        prepare-payload: OK
    # action: dynatrace.automations:run-javascript ...
```

```
prepare-payload
   ├─ create-snow
   └─ create-pd
```

---

### 8) Join after parallel (wait for both)

**What:** Cross-link comment only when both OK.

```yaml
  cross-link:
    name: cross-link
    position: { x: 0, y: 3 }
    predecessors:
      - create-snow
      - create-pd
    conditions:
      states:
        create-snow: OK
        create-pd: OK
```

---

### 9) ServiceNow Create Incident (Connection)

**What:** Uses ServiceNow app action + Connection (not classic Problem notification).

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
workflow:
  # ... davis-problem OPEN trigger ...
  tasks:
    create-servicenow-incident:
      name: create-servicenow-incident
      action: dynatrace.servicenow:snow-create-incident
      active: true
      position: { x: 0, y: 2 }
      predecessors: [prepare-payload]
      conditions:
        states:
          prepare-payload: OK
      input:
        connectionId: ""
        correlationId: '{{ result("prepare-payload").problemId }}'
        shortDescription: '{{ result("prepare-payload").title }}'
        description: '{{ result("prepare-payload").problemUrl }}'
        impact: "3"
        urgency: "3"
```

On upload: map Connection (e.g. `ServiceNowTest`). Allowlist: `silvastg.service-now.com`.

---

### 10) PagerDuty trigger + resolve pair

**Open task (trigger):**

```javascript
const routingKey = "__PD_ROUTING_KEY__";
const body = {
  routing_key: routingKey,
  event_action: "trigger",
  dedup_key: p.dedupKey,
  payload: {
    summary: p.title,
    source: "dynatrace",
    severity: "error"
  }
};
await fetch("https://events.pagerduty.com/v2/enqueue", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body)
});
```

**Close task (resolve) — second workflow:**

```javascript
const body = {
  routing_key: "__PD_ROUTING_KEY__",
  event_action: "resolve",
  dedup_key: p.dedupKey
};
await fetch("https://events.pagerduty.com/v2/enqueue", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body)
});
```

Allowlist: `events.pagerduty.com`.  
Full open/close YAML: pack `2026-09-14/8-snow-classic-notification-yaml-json/`.

---

## 3) Template expressions (task input)

| Expression | Meaning |
| --- | --- |
| `{{ result("prepare-payload").problemId }}` | Field from earlier task result |
| `connectionId: ""` | Filled by Connection mapping at import/UI |

---

## 4) Common mistakes

| Mistake | Fix |
| --- | --- |
| `y: 0` | Start positions at `y: 1` |
| `categories: []` | Use `{ error: true, ... }` |
| One workflow for open and close | Split into two workflows |
| External call without allowlist | Add host under External requests |
| Left `__PD_ROUTING_KEY__` | Replace before Activate |
| Uploaded Settings JSON as Workflow | Wrong product area |

---

## Data flow map

```
Trigger (Problem / schedule)
  → Task 1 prepare (JS)
  → Task 2a / 2b parallel (SNOW / PD / HTTP)
  → Task 3 join (optional)
  → Executions history → external system
```

## Related files

| Path | Why |
| --- | --- |
| `4-dynatrace-workflow-top10-examples.yaml` | Compact examples file |
| `../3-failed-uploads-match-pending-syntax/` | Log alert (not Workflow) |
| `2026-09-14/8-snow-classic-notification-yaml-json/` | Full PD-only workflows |
| `4.sh` | Paths |

## Commands

See `4.sh` in this folder.
