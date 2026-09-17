# Glossary

| Term | What it means |
| --- | --- |
| Workflow | Automation with trigger + tasks |
| Trigger | When the workflow starts |
| Task | One step on the canvas |
| Action | Task type (JS, ServiceNow, HTTP, …) |
| Draft | Saved but not live |
| Activate | Make the workflow live |
| Deactivate | Pause without deleting |
| Predecessor | Task that must finish first |
| Condition / OK | Gate so next step runs only on success |
| Connection | Saved integration credentials |
| Expression | `{{ result("task").field }}` to pass data |
| Execution | One recorded run with logs |
| Allowlist / External requests | Hosts Dynatrace may call outbound |
| filterQuery | Extra filter on trigger events |
| Dedup key | Shared id so PD open/close match |
| Classic Problem notification | Settings push to SNOW (not a Workflow Connection) |
