# Investigation

| Item | Value on screen |
|---|---|
| Time | 06:56 to 08:56 on 2026-11-12. |
| Rows | 819. |
| Filter | `aws.log.group` contains `/aws/lambda/`. |
| ERROR example | "Failed to handle" on `light-digital-api-dev-confirm-e-signature`. |
| INFO example | START, END, and REPORT on the Jenkins SharePoint function. |
| Bottom query | `timeseries { log_count = count() }` with an empty filter. |
