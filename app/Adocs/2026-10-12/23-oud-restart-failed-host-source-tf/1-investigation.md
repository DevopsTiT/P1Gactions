# OUD Restart Failed Host And Source Investigation

| What was checked | Finding |
|---|---|
| index=ods sources | 4 values, all under `/opt/oracle/oud/` |
| Biggest source | asinst_1 access log, 98.658% |
| Errors logs | asinst_1 errors 1.33%, asinst_2 errors 0.012% |
| Sourcetypes | 2. Which files are `oud_service` is not shown. |
| Host | WPALJA2162.prprivmgmt.intraxa only |
| Open question | Confirm `oud_service` maps to the errors logs with a Splunk `stats count by source`. |
