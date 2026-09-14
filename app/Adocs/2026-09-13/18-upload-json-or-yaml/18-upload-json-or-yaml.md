# Upload JSON Or YAML

```
Which file to upload?
  │
  ├─ Prefer YAML templates (easier to edit placeholders)
  │     create: ago-problem-to-snow-pagerduty.workflow-template.yaml
  │     close:  ago-problem-closed-resolve-snow-pd.workflow-template.yaml
  │
  ├─ Or JSON (same logic, flatter upload shape)
  │     create: problem-to-snow-pagerduty.workflow.json
  │     close:  problem-closed-resolve-snow-pd.workflow.json
  │
  └─ Never: upload YAML + JSON for the same workflow
       Always: upload TWO workflows (create + close), one format each
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Recommendation | **YAML** for both create and close |
| Alternative | JSON if you already use JSON exports / API style |
| How many uploads | **Two** (open create + close resolve) |
| Same format both? | Yes — pick YAML for both, or JSON for both |
| Do not | Upload create YAML and create JSON together |

## Summary

Upload the two **YAML templates** unless you specifically want JSON. Logic is identical; YAML is easier to edit. You still need two workflows: one for Problem open, one for Problem close.

## What to upload (recommended)

| Workflow | File |
| --- | --- |
| Create (Problem open) | `ago-problem-to-snow-pagerduty.workflow-template.yaml` |
| Close (Problem closed) | `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` |

Folder: `../4-snow-pd-workflow-yaml-and-json/`

## If you choose JSON instead

| Workflow | File |
| --- | --- |
| Create | `problem-to-snow-pagerduty.workflow.json` |
| Close | `problem-closed-resolve-snow-pd.workflow.json` |

## YAML vs JSON

| Topic | YAML template | JSON workflow |
| --- | --- | --- |
| Edit placeholders | Easier (multi-line scripts) | Harder (escaped strings) |
| Upload type | Template | Workflow |
| Logic | Same | Same |
| Dynatrace docs | Upload supports both | Upload supports both |

## Before upload

1. Replace `__SNOW_*__` and `__PD_ROUTING_KEY__`  
2. Edit `assignMap`  
3. Upload create file → set Active  
4. Upload close file → set Active  

## Data flow map

```
You choose format once
  → Upload CREATE (YAML or JSON)
  → Upload CLOSE  (same format preferred)
  → Do not upload both formats for create
```

## Related files

| Path | Why |
| --- | --- |
| `../4-snow-pd-workflow-yaml-and-json/` | The four files |
| `../3-dynatrace-workflow-json-or-yaml/` | Format background |
| `../9-one-or-two-workflow-files/` | Why create + close stay separate |
| `18.sh` | Reminders |

## Commands

See `18.sh` in this folder.
