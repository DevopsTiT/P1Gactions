# cmdb_ci Result

| Step | Action |
|---|---|
| 1 | Optional: run 31.sh line 1 to see which offering ts12 tickets used. |
| 2 | Re-import 30-preview-then-post-v7-1.workflow.yaml (set DRY_RUN true for the first run if you want no send). |
| 3 | Rerun on a ts12 problem. Check resolve-snow-values offering_history and build-payload cmdb_ci. |
| 4 | If history is empty, ask CMDB to link ts12 to the business service or use SERVICE_MAP. |
