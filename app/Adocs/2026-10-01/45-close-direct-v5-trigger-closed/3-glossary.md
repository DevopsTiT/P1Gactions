# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Event state | The trigger setting for which problem changes start the workflow. | "closed" = only when the problem ends. |
| `triggerOn` | YAML field for Event state (open, open-and-close, close). | v5 sets `close`. |
| `onProblemClose` | Older yes/no switch for "also run on close". | Alone, it shows as "active or closed". |
| `is_closed` guard | Code check in prepare-close. | Stops a close run if the problem is still open. |
| `incident_state` | SILVA's real state field on the incident form. | Must be set to Resolved, or the state does not change. |
| `dedup_key` | PagerDuty ID that links trigger and resolve. | `dt-problem-<display_id>` in both workflows. |
| Deploy vs Draft | Draft workflows never fire on events. | Always Deploy after saving. |
