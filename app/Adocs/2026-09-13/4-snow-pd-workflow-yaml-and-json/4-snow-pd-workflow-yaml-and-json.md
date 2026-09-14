# SNOW PD Workflow YAML And JSON

Generated from `1-dynatrace-workflow-snow-pagerduty` guide (same logic as seq 2 YAML).

```
Need file for Dynatrace Upload?
  │
  ├─ Template share / new tenant → *.workflow-template.yaml
  └─ Full workflow / API create   → *.workflow.json
```

| File | Format | Upload as |
| --- | --- | --- |
| `ago-problem-to-snow-pagerduty.workflow-template.yaml` | YAML | **Template** |
| `problem-to-snow-pagerduty.workflow.json` | JSON | **Workflow** |
| `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` | YAML | **Template** |
| `problem-closed-resolve-snow-pd.workflow.json` | JSON | **Workflow** |

## Summary

Both formats implement: Problem open → prepare → parallel ServiceNow + PagerDuty → cross-link; Problem close → resolve both.

## Before use

Replace `__SNOW_*__` and `__PD_ROUTING_KEY__` placeholders. Prefer ServiceNow **Connection** in UI after import instead of password in script.

## Upload

1. Workflows → **Upload**
2. YAML → template path (map apps/connections)
3. JSON → workflow path (Replace / Keep both if ID exists)

Docs: [Upload](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/manage-workflows/workflows-upload)

## Related

| Path | Purpose |
| --- | --- |
| `../1-dynatrace-workflow-snow-pagerduty/` | Design guide |
| `../3-dynatrace-workflow-json-or-yaml/` | JSON vs YAML explainer |
| `4.sh` | Reminders |
