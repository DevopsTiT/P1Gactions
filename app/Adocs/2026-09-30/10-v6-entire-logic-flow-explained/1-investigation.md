# Investigation

| Source read | What was taken from it |
|---|---|
| v6 YAML task extract-event-tags | Steps 1.1 to 1.9 |
| v6 YAML task resolve-snow-values | Steps 2.1 to 2.7 |
| v6 YAML task display-result | Steps 3.1 to 3.5 |
| v6 YAML task post-silva-incident | Steps 4.1 to 4.6 |
| v6 YAML task trigger-pagerduty | Steps 5.1 to 5.6 |
| input4.sh Oracle event | Walkthrough values |

| Finding | Why it matters |
|---|---|
| The Oracle event has `AGO_Maintenance:True` | With SKIP_WHEN_MAINTENANCE true it never creates a ticket |
| Trigger uses status_transition CREATED | One run per problem; duplicate check is a safety net |
