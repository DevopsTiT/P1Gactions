# Problem SNOW PD Workflow YAML

```
AGO hosts YAML style
  → same schemaVersion / dynatrace.automations / run-javascript tasks
  → this pack = Problem → SNOW + PD parallel
```

| File | Purpose |
| --- | --- |
| `ago-problem-to-snow-pagerduty.workflow-template.yaml` | Create INC + PD on Problem open |
| `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` | Resolve both on Problem close |

## Before import

Replace placeholders:

| Placeholder | Meaning |
| --- | --- |
| `__SNOW_INSTANCE_URL__` | `https://xxx.service-now.com` |
| `__SNOW_USER__` / `__SNOW_PASSWORD__` | Integration user |
| `__SNOW_CALLER_SYS_ID__` | Caller user sys_id |
| `__SNOW_GROUP_SYS_ID_*__` | Assignment groups |
| `__SNOW_BIZ_SYS_ID_*__` | Business services |
| `__PD_ROUTING_KEY__` | PagerDuty Events API v2 key |

Prefer switching `create-servicenow-incident` to the **ServiceNow Connector → Create Incident** action in the UI after import (secrets stay in Connections).

## Import

Dynatrace → **Workflows** → import / upload template (or paste tasks). Allow external requests to ServiceNow + `events.pagerduty.com`.
