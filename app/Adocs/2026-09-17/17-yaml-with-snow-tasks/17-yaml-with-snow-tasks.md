# Yaml With Snow Tasks

```
Want "snow notification task" in workflow YAML?
  │
  ├─ Problem notification is NOT a workflow task (no such action)
  │
  └─ Use real SNOW Connection tasks instead:
        OPEN:  create-servicenow-incident + cross-link-snow-pd
        CLOSE: search-snow-incident + resolve-snow-incident
        + PagerDuty tasks
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What you get | Workflow YAML **with snow tasks** (Connection actions) |
| What does not exist | A task that “runs” Problem notification `servicenowstg` |
| Notification YAML | Separate file: `servicenowstg-problem-notification.settings.json` |
| Avoid duplicates | If using these snow tasks → set classic **ITSM OFF** |

## Summary

Upload the open/close workflow YAML below. They include ServiceNow tasks. Keep classic notification for ITOM only (ITSM OFF), or you will create two INCs.

---

## Investigation

User asked for YAML with a snow notification task. Dynatrace Workflows only support Connection-based `snow-*` actions, not Problem notification as a task.

## Result

| File | Role |
| --- | --- |
| `1-open-with-snow-tasks.workflow.yaml` | OPEN with SNOW + PD |
| `2-close-with-snow-tasks.workflow.yaml` | CLOSE with SNOW + PD |
| `servicenowstg-problem-notification.settings.json` | Settings backup (not a workflow) |

Path: `Daily Files/2026-09-17/17-yaml-with-snow-tasks/`

---

## Snow tasks inside the OPEN YAML

| Task name | Action |
| --- | --- |
| prepare-payload | JS |
| **create-servicenow-incident** | `dynatrace.servicenow:snow-create-incident` |
| create-pagerduty-incident | JS (parallel) |
| **cross-link-snow-pd** | `dynatrace.servicenow:snow-comment-on-incident` |

## Snow tasks inside the CLOSE YAML

| Task name | Action |
| --- | --- |
| prepare-close-ids | JS |
| **search-snow-incident** | `dynatrace.servicenow:snow-search-incidents` |
| **resolve-snow-incident** | `dynatrace.servicenow:snow-resolve-incident` |
| resolve-pagerduty | JS |

---

## Setup

1. Settings → **Connections** → ServiceNow → `https://silvastg.service-now.com`  
2. Classic `servicenowstg`: **ITSM OFF** (workflow creates INC); ITOM optional ON  
3. Allowlist: `silvastg.service-now.com` + `events.pagerduty.com`  
4. Edit `__PD_ROUTING_KEY__` + assignMap sys_ids  
5. Upload both YAML → map Connection → Activate → test  

---

## Data flow map

```
Problem OPEN
  workflow snow-create-incident → SNOW INC
  workflow PD trigger
  workflow snow-comment (PD key)
  (optional) notification ITOM event only

Problem CLOSE
  workflow snow-search → snow-resolve
  workflow PD resolve
```

## Related files

| Path | Why |
| --- | --- |
| YAML in this folder | Workflows with snow tasks |
| `../15-.../` | PD-only (no snow task; notification owns INC) |
| `../16-why-no-snow-task-in-yaml/` | Why notification ≠ task |
| `17.sh` | Paths |

## Commands

See `17.sh` in this folder.
