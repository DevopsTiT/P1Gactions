# Result

| Step | Action |
|---|---|
| 1 | Import `34-v7-1-workflows-ts12-result-preview-then-post.workflow.yaml` (set DRY_RUN true if you do not want to send yet). |
| 2 | Rerun on P-261090. |
| 3 | Check cmdb_ci is `cfbf255f…` and u_business_service is `37273dbc…`. |
| 4 | Run `34.sh` lines 2 and 3 to confirm the company matches past ts12 tickets. |
| 5 | After a real send, run `34.sh` line 4 to see the created incident. |

From now on, every new workflow version or result goes into a new numbered folder.
