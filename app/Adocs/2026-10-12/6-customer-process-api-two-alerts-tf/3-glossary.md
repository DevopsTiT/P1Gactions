# Glossary

| Term | What it means | Why you care |
|---|---|---|
| HTTP 201 | "Created": the request made a new resource. | Alert 1 fires on success. |
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces both alerts. |
| `alertIdentityFields` | Fields that group rows into one problem. | One problem per log group. |
| `caseSensitive:false` | Match regardless of case. | Used on Alert 2's messages. |
| `<StatusCd>EB` | XML status code EB from a backend response. | One of Alert 2's error signals. |
| Too many connections | The database refused new connections. | Usually a connection-pool or Lambda concurrency issue. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"0"` for both. |
