# Investigation

| Evidence | What it shows |
|---|---|
| Screenshot of v1 trigger panel | Event state "active or closed". |
| Screenshot of the dropdown | Options active, active or closed, closed exist. |
| v1 to v4 YAML | Only `onProblemClose: true`, which maps to "active or closed". |
| Terraform `dynatrace_automation_workflow` docs | `trigger_on` = open, open-and-close, close; `on_problem_close` deprecated. |
| Validation of v5 | Ruby YAML parse OK; `node --check` OK on prepare-close, close-silva-incident, close-pagerduty. |

Open point: the exact import key name `triggerOn` is inferred from the Terraform field; confirm in the panel after import.
