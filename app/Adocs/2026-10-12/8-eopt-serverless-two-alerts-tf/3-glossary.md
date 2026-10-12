# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces both alerts. |
| `fields` | Keeps only the listed columns. | Alert 1's filtered output. |
| `loglevel` | Grail field for the log level. | Dynatrace name for "level". |
| `alertIdentityFields` | Fields that group rows into one problem. | Must stay in the output. |
| Scheduled workflow | Workflow started at a fixed time. | Needed for a daily 10:00 email. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"0"` for both. |
