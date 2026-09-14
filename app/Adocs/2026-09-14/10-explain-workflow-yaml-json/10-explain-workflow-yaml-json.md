# Explain Workflow Yaml Json

```
What are these files?
  │
  ├─ YAML (.yaml) — human-friendly text; preferred for Dynatrace Workflow upload
  ├─ JSON (.json) — same data, stricter braces; good for review / Settings API
  │
  ├─ Workflow files → Automations (PagerDuty open/close)
  └─ Notification files → classic silvastg Problem notification (Settings)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| YAML and JSON | Two text formats for the same kind of structured data |
| Your workflows | YAML for upload; JSON is a twin copy of the same workflow |
| Classic SNOW | Separate Settings JSON/YAML — not a workflow file |
| Rule of thumb | Upload **workflow YAML**; keep JSON for reading/API |

## Summary

YAML and JSON both store “objects with fields.” Dynatrace Workflows usually import the `.workflow-template.yaml` files. The `.workflow.json` files mirror the same design so you can read or compare them easily. The `silvastg-problem-notification*.json/yaml` files describe the classic Problem notification, which lives under Settings — not under Workflows.

---

## Investigation

Pack explained: `8-snow-classic-notification-yaml-json` (PD-only workflows + classic notification export). Connection pack from earlier is different and not required for this path.

## Result

Use the sections below: basics → file map → workflow anatomy → notification anatomy → placeholders → upload choice.

---

## 1) What YAML and JSON are (plain English)

Think of both as a **recipe card** for Dynatrace: title, trigger, tasks, settings.

| Idea | YAML | JSON |
| --- | --- | --- |
| What it is | Structured text using indentation | Structured text using `{ } [ ]` and commas |
| Easy to edit by hand? | Usually yes | Harder when nested deep |
| Comments | `# comment` allowed | No real comments |
| Strings | Often unquoted | Must use `"quotes"` |
| Dynatrace Workflow upload | Prefer `.yaml` templates | JSON twins for review / some APIs |
| Classic notification | Monaco YAML or Settings API JSON | Settings API POST body |

**Same meaning, different spelling:**

YAML:

```yaml
title: AGO - Problem to PagerDuty
type: STANDARD
```

JSON:

```json
{
  "title": "AGO - Problem to PagerDuty",
  "type": "STANDARD"
}
```

If YAML and JSON describe the **same** workflow, Dynatrace should behave the same after import — as long as the schema fields match what the tenant accepts.

---

## 2) File map in your pack (what each file is for)

Folder: `Daily Files/2026-09-14/8-snow-classic-notification-yaml-json/`

### A) Workflow files (Automations)

| File | Format | Purpose |
| --- | --- | --- |
| `ago-problem-to-pagerduty-only.workflow-template.yaml` | YAML | **Upload this** — Problem OPEN → PagerDuty |
| `ago-problem-closed-resolve-pagerduty-only.workflow-template.yaml` | YAML | **Upload this** — Problem CLOSED → resolve PD |
| `problem-to-pagerduty-only.workflow.json` | JSON | Twin of open workflow (read/compare) |
| `problem-closed-resolve-pagerduty-only.workflow.json` | JSON | Twin of close workflow |

### B) Classic ServiceNow notification files (Settings — not Workflow)

| File | Format | Purpose |
| --- | --- | --- |
| `silvastg-problem-notification.settings.json` | JSON | Settings API shape for notification `silvastg` |
| `silvastg-problem-notification.template.json` | JSON | Monaco template body |
| `silvastg-problem-notification.monaco.yaml` | YAML | Monaco project stub pointing at the template |

You already configured `silvastg` in the UI. These files are optional backups / as-code copies.

---

## 3) Workflow YAML — section by section

Example: open file `ago-problem-to-pagerduty-only.workflow-template.yaml`

### Top: metadata (template packaging)

```yaml
metadata:
  version: "1"
  dependencies:
    apps:
      - id: dynatrace.automations
        version: ^1.3301.5
  inputs: []
```

| Field | What it means |
| --- | --- |
| `metadata.version` | Template package version |
| `dependencies.apps` | Apps the workflow needs (here: Automations / JS) |
| `inputs` | Extra inputs at import time (empty here — no ServiceNow Connection picker) |

Older Connection pack had `inputs` with `type: connection` so upload could map `ServiceNowTest`. This PD-only pack does **not** need that.

### Middle: workflow identity + trigger

```yaml
workflow:
  title: AGO - Problem to PagerDuty (SNOW via classic notification)
  description: ...
  schemaVersion: 3
  trigger:
    eventTrigger:
      isActive: true
      filterQuery: >-
        event.kind == "DAVIS_PROBLEM" AND event.status == "ACTIVE" AND ...
      triggerConfiguration:
        type: davis-problem
        value:
          categories:
            error: true
            resource: true
            ...
          entityTags: {}
```

| Field | What it means |
| --- | --- |
| `title` | Name you see in Workflows UI |
| `schemaVersion` | Workflow definition version Dynatrace expects |
| `trigger.eventTrigger` | When the workflow runs |
| `filterQuery` | Extra filter on Problem events (open vs close) |
| `type: davis-problem` | Davis / Problem-based trigger |
| `categories` | Which problem kinds fire (must be a **map/dict**, not `[]`) |
| `entityTags` | Optional tag filter (`{}` = none) |

Open vs close difference is mostly in `filterQuery` (ACTIVE/CREATED vs CLOSED/RESOLVED).

### Tasks: the work

```yaml
  tasks:
    prepare-payload:
      name: prepare-payload
      action: dynatrace.automations:run-javascript
      position: { x: 0, y: 1 }
      predecessors: []
      input:
        script: |
          ... JavaScript ...

    create-pagerduty-incident:
      ...
      predecessors:
        - prepare-payload
      conditions:
        states:
          prepare-payload: OK
```

| Field | What it means |
| --- | --- |
| `tasks.<id>` | One box on the canvas |
| `action` | Which Dynatrace action runs (here: Run JavaScript) |
| `position` | Canvas layout; `y` should be ≥ 1 for upload |
| `predecessors` | Must finish before this task starts |
| `conditions.states` | Only run if prior task state is OK |
| `input.script` | The JavaScript source (YAML uses `\|` for multi-line) |

**Open flow:**

```
prepare-payload → create-pagerduty-incident
```

**Close flow:**

```
prepare-close-ids → resolve-pagerduty-incident
```

### What the JavaScript is doing (inside YAML/JSON)

| Task | Job |
| --- | --- |
| `prepare-payload` | Read Problem event → build `problemId`, `dedupKey`, title, severity |
| `create-pagerduty-incident` | HTTP POST to `events.pagerduty.com` with `event_action: trigger` |
| `prepare-close-ids` | Build same `dedupKey` pattern |
| `resolve-pagerduty-incident` | Same API with `event_action: resolve` |

Placeholder you must change in UI or file:

```text
__PD_ROUTING_KEY__
```

That is your PagerDuty Events API v2 routing key.

---

## 4) Workflow JSON twin — how it maps to YAML

File: `problem-to-pagerduty-only.workflow.json`

JSON usually starts at the **workflow body** (title, trigger, tasks), without the outer `metadata:` wrapper used by some YAML templates.

| YAML path | JSON path |
| --- | --- |
| `workflow.title` | `"title"` |
| `workflow.trigger` | `"trigger"` |
| `workflow.tasks.prepare-payload` | `"tasks"."prepare-payload"` |
| `input.script: \|` block | `"input"."script": "line\\nline\\n..."` |

In JSON, the whole script becomes **one long string** with `\n` for newlines. That is why YAML is nicer to edit by hand.

**Use JSON when:**

- You want to inspect structure quickly
- An API or tool expects JSON
- You compare two versions in a diff tool that prefers JSON

**Use YAML when:**

- Uploading into Dynatrace Workflows (recommended for your pack)
- Editing scripts and comments

---

## 5) Classic notification JSON/YAML (different product area)

### Settings API JSON

`silvastg-problem-notification.settings.json`

```json
{
  "schemaId": "builtin:problem.notifications",
  "scope": "environment",
  "value": {
    "enabled": true,
    "type": "SERVICE_NOW",
    "displayName": "silvastg",
    "alertingProfile": "__ALERTING_PROFILE_ID__",
    "serviceNowNotification": {
      "instanceName": "silvastg",
      "username": "Tech_DynatraceINC_WS",
      "password": "__SNOW_PASSWORD__",
      "message": "{State} {ProblemImpact} Problem {ProblemID}: {ProblemTitle}",
      "sendIncidents": false,
      "sendEvents": true,
      "formatProblemDetailsAsText": false
    }
  }
}
```

| Field | What it means |
| --- | --- |
| `schemaId` | Which Settings “form” this is |
| `displayName` | Name in Problem notifications UI |
| `instanceName` | `silvastg` → `silvastg.service-now.com` |
| `sendIncidents` | ITSM INC tickets (your UI: false) |
| `sendEvents` | ITOM events (your UI: true) |
| `message` | Text template with Dynatrace placeholders like `{ProblemID}` |

This file does **not** create a Workflow. It describes the same thing as **Settings → Problem notifications → silvastg**.

### Monaco YAML

`silvastg-problem-notification.monaco.yaml` points at the template JSON for Monitoring as Code. Only needed if your team deploys Settings via Monaco — not required for the Workflow UI steps.

---

## 6) Placeholders cheat sheet

| Placeholder | Where | Replace with |
| --- | --- | --- |
| `__PD_ROUTING_KEY__` | Workflow YAML/JSON JS | Real PagerDuty routing key |
| `__SNOW_PASSWORD__` | Notification Settings JSON | SNOW user password (secret) |
| `__ALERTING_PROFILE_ID__` | Notification Settings JSON | Default (or chosen) alerting profile object id |

Do not commit real passwords or routing keys to Git if your repo is shared.

---

## 7) What to upload where

| Goal | File | Where in Dynatrace |
| --- | --- | --- |
| Live PagerDuty on Problem open | `ago-problem-to-pagerduty-only.workflow-template.yaml` | Workflows → Upload |
| Live PagerDuty on Problem close | `ago-problem-closed-resolve-pagerduty-only.workflow-template.yaml` | Workflows → Upload |
| Review same workflow as JSON | `problem-*-pagerduty-only.workflow.json` | Optional — usually do not need to upload both |
| As-code classic SNOW | `silvastg-problem-notification.settings.json` | Settings API / Monaco (optional; UI already set) |

```
Upload YAML workflow  →  Workflows canvas
Keep classic silvastg →  Problem notifications (UI or Settings JSON)
Do not expect workflow JSON to configure silvastg notification
Do not expect silvastg JSON to create PagerDuty tasks
```

---

## 8) Common mistakes

| Mistake | What happens |
| --- | --- |
| Upload notification JSON as a workflow | Import fails or wrong place |
| Upload both YAML and JSON as two workflows | Duplicate automations |
| Leave `__PD_ROUTING_KEY__` unchanged | PagerDuty call fails |
| Put ServiceNow Connection tasks back while classic owns SNOW | Confusion / possible duplicates |
| Use old upload fields (`categories: []`, `y: 0`) | Schema Error 400 (fixed in current pack) |

---

## Data flow map

```
YAML/JSON on disk
  │
  ├─ *.workflow-template.yaml ──upload──► Workflows
  │         └─ JS tasks ──► events.pagerduty.com
  │
  ├─ *.workflow.json ──(optional twin)──► same design, easier to diff
  │
  └─ silvastg-*.settings.json ──API/Monaco──► Problem notifications
            └─ Dynatrace ──► silvastg.service-now.com (ITOM events)
```

## Related files

| Path | Why |
| --- | --- |
| `../8-snow-classic-notification-yaml-json/` | The files this guide explains |
| `../9-set-workflow-ui-step-by-step/` | How to set them in UI |
| `10.sh` | Path reminders |

## Commands

See `10.sh` in this folder.
