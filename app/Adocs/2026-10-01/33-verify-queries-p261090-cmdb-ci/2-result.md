# Result

| Step | Action |
|---|---|
| 1 | Run `33.sh` lines 2 and 6. |
| 2 | If either returns rows, run lines 3, 4, 7 and note the offering sys_id. |
| 3 | Re-import seq 30 workflow and rerun on P-261090 (set DRY_RUN true if you do not want to post yet). |
| 4 | Compare build-payload with the table in the main md. |
| 5 | After a real POST, run line 10 with the problem id, or line 11. |
| 6 | If lines 2 and 6 are both empty, send me lines 3 and 4 output; then use SERVICE_MAP or a CMDB fix. |
