# Result

Paste the queries in `18-splunk-alerts-to-dql.md`. Each PODFrozen query returns `host` and `Message` only when the distinct pod-or-host count is not the expected number.

| Token | Expected names |
|---|---|
| `alfrescoacr-batch` | 4 |
| `agrex` | 1 |
| `alfrescoacr` | 3, excluding `alfrescoacr-batch` |
| `alfrescocollabsrv` | 1 |
| `bc2-batch` | 2 |
| `pc2-batch` | 2 |
| `bc2-ui` | 2 |
| `cm2-ui` | 2 |
| `mailservice` | 1 |

BAU-4050 returns matching lines from `pc2-batch`. The reimbursement check returns matching lines from `bc2-ui`.
