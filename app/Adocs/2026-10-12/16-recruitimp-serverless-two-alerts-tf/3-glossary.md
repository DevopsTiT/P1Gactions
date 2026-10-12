# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces both alerts. |
| `level:ERROR` | This Lambda's log-level marker. | Precise error signal. |
| `caseSensitive:false` | Match regardless of case. | Makes the Alert 1 OR redundant. |
| Scheduled workflow | Workflow started at a fixed time. | Needed for an 08:00 daily email. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"0"` for both. |
