# Claim Job Over Run TF Explained Result

| Time | Log line | Problem |
|---|---|---|
| 20:00 | STARTED | None (0 minutes) |
| 20:15 | No new line | Opens, email |
| 20:16 to 20:29 | No new line | Same problem stays |
| 20:30 | EXECUTION ENDED | Closes |

## Next steps

| Step | Why |
|---|---|
| Fill `claims_jobs` | Otherwise nothing matches. |
| Run answer 40 check queries 2 and 4 | Confirm parse and the 15 minute limit. |
| `terraform validate` and `plan` | Check before apply. |
