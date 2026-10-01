# Input To cmdb_ci Result

| Step | Action |
|---|---|
| 1 | Run 32.sh lines 1 and 2. |
| 2 | If either returns rows, re-import seq 30 and rerun: cmdb_ci will be filled. |
| 3 | If both are empty, send line 3 and 4 output; then add SERVICE_MAP or ask CMDB to link ts12. |
