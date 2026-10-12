# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces both alerts. |
| `alertIdentityFields` | Fields that group rows into one problem. | Replaces the throttle. |
| `caseSensitive:false` | Match regardless of upper or lower case. | Missing in alert 2. |
| Scheduled workflow | Workflow started at a fixed time. | Needed for a daily 10:00 email. |
| `sort` and `limit` | Order rows and cap their number. | Not needed in a detector. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"0"` for both. |
