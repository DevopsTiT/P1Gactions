# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Threshold | Count that must be passed before alerting. | 5 here. |
| `summarize count()` | Counts rows into one result. | Needed for a threshold above 0. |
| `status` | Normalised log level in Grail. | Filter field for error and warn. |
| `alertIdentityFields` | Fields that group rows into one problem. | Uses the fixed `scope` value. |
| DeprecationWarning | Node.js warning about outdated code. | Excluded as noise. |
| Rolling window | The last N minutes, re-checked every minute. | Catches bursts across block edges. |
