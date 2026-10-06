# Datalake Batch Result Outcome

| Item | Result |
|---|---|
| New filter | `contains(log.source, "datalake_transfer.log")` |
| Terraform file | `12-datalake-batch-result-source-fix.tf` |
| Severity | low |
| PagerDuty | `"0"` |
| Apply rule | Apply only this version. It replaces seq 11 and Oct 5 seq 43. |
| First check | Run check query 1 to confirm the file reaches Dynatrace. |
| Follow-up | Ask the Datalake team about the nightly LINEBOT.csv delete failure. |
