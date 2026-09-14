# Result

To monitor the demo: keep Dynatrace Executions, ServiceNow, and PagerDuty open; open one test Problem; confirm the create workflow’s four tasks and matching INC/PD/cross-link; close the Problem; confirm the close workflow resolves the same INC and PD via shared keys.

| Half | Pass signal |
| --- | --- |
| Create | 4/4 tasks OK + INC + PD + work notes `dedup_key` |
| Close | Resolve task OK + INC Resolved + PD resolved |
