# Investigation

| Checked | Finding |
| --- | --- |
| File | `problem-to-snow-pagerduty.workflow.json` |
| Trigger | davis-problem, onProblemClose false |
| Tasks | prepare, create-servicenow, create-pagerduty, cross-link |
| Action type | All run-javascript |

Parsed with Python to confirm predecessors/positions.
