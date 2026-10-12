# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces each alert. |
| `functionName :: message` | Error marker format in these logs. | Every filter uses it. |
| Queue consumer | Function that processes jobs from a queue. | Alerts 3 and 4. |
| Copy-paste filter | A filter copied from another alert and not updated. | Suspected in Alert 4. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"0"` here; confirm. |
