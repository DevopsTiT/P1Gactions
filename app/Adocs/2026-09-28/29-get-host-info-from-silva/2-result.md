# Result

| Step | Action |
|---|---|
| 1 | Find the host in cmdb_ci_server (UI or 29.sh line 1). |
| 2 | Read its business service from svc_ci_assoc (line 2). |
| 3 | Read the service's support group and offerings (lines 3 and 4). |
| 4 | Confirm group and environment labels (lines 5 and 6). |
| 5 | If the API returns nothing but the UI does, request read access for Tech_DynatraceJP_WS. |
