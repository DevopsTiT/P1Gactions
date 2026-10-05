# Glossary

| Term | What it means |
|---|---|
| Daily digest | A check that runs once a day and reports what happened in the last 24 hours |
| `dynatrace_automation_workflow` | Terraform resource for a Dynatrace workflow (tasks plus a trigger) |
| Schedule trigger | Starts a workflow at set times, like cron |
| `execute-dql-query` | Workflow action that runs a DQL query and returns records |
| `send-email` | Workflow action that sends an email |
| Task condition | A rule that decides whether a task runs, for example only when a count is above 0 |
| `davis_problem` trigger | Starts a workflow when a matching problem opens or closes |
| `custom_filter` | Extra DQL matcher on the problem, such as its name |
| `caseSensitive: false` | Makes `contains` ignore upper and lower case |
