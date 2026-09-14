# Result

Four files are two Dynatrace workflows (open create, close resolve), each available as readable YAML template and as JSON upload twin. Logic is the same; upload one format per workflow, keep open and close separate, replace placeholders before use.

| Use | File |
| --- | --- |
| Create on open (YAML) | `ago-problem-to-snow-pagerduty.workflow-template.yaml` |
| Create on open (JSON) | `problem-to-snow-pagerduty.workflow.json` |
| Resolve on close (YAML) | `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` |
| Resolve on close (JSON) | `problem-closed-resolve-snow-pd.workflow.json` |
