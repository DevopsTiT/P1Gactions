# Result

| Step | Do this |
|---|---|
| 1 | Run `check.dql` queries 1 and 2 to choose alert 2's exact match |
| 2 | Confirm when the import batch runs (weekends, time of day) |
| 3 | Apply the import-check scheduled workflow |
| 4 | Apply the 2 detectors and the shared email workflow for alerts 1 and 3 |
| 5 | `terraform validate` and `plan` (expect 2 detectors and 2 workflows) |
