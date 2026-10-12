# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces the scheduled alert. |
| `alertIdentityFields` | Fields that group rows into one problem. | Replaces the throttle. |
| Scheduled workflow | Workflow started at a fixed time. | Needed for a 10:00 daily email. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"0"` here. |
| S3 | AWS object storage. | One side of the file transfer. |
