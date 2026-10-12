# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces the scheduled alert. |
| `alertIdentityFields` | Fields that group rows into one problem. | Replaces the 60-minute throttle. |
| `alert.severity` | Severity copied onto the problem. | Medium, from the old action. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"0"` here. |
| `caseSensitive:false` | Match regardless of upper or lower case. | "Error", "ERROR" and "error" all match. |
