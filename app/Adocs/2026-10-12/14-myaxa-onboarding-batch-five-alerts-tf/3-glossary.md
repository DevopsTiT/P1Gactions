# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces all five alerts. |
| Queue consumer | Code that reads jobs from a queue and processes them. | Alerts 3 to 5 watch it. |
| `function :: message` | This batch's log format. | Each alert matches one message. |
| Copy-paste slip | A block copied from another and not fully edited. | Alerts 4 and 5. |
| Case-sensitive match | Upper and lower case must match exactly. | All five filters. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"0"` for all. |
