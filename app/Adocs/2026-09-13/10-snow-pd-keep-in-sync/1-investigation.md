# Investigation

| Checked | Finding |
| --- | --- |
| Create workflow | Parallel SNOW + PD, then `cross-link-snow-pd` |
| Close workflow | Search `correlation_id`, resolve INC, PD `resolve` with same `dedup_key` |
| Design seq 8 | Problem ID is shared identity; Dynatrace owns lifecycle |
| User question | How to keep SNOW and PD in sync |

## Evidence paths

- `../4-snow-pd-workflow-yaml-and-json/ago-problem-to-snow-pagerduty.workflow-template.yaml`
- `../4-snow-pd-workflow-yaml-and-json/ago-problem-closed-resolve-snow-pd.workflow-template.yaml`
- `../8-dynatrace-snow-pd-detailed-design/8-dynatrace-snow-pd-detailed-design.md`
