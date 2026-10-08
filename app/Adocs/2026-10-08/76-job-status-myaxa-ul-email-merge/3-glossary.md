# CHDE010M MyAXA UL Glossary

| Term | What it means | Why you care |
|---|---|---|
| Control-M | The batch job scheduler. | CHDE010M is one of its jobs. |
| CHDE010M | The batch that creates MyAXA UL data, weekly and monthly. | This alert checks that it finished. |
| odate | Control-M order date: the business day a job run belongs to. | Here it is 6 digits (yyMMdd). |
| Ended OK | Control-M status for a successful run. | Anything else means "要確認". |
| 正常終了していません要確認 | "Did not end normally, please check." | The message the problem carries. |
| dedup odate | Splunk keeps only the latest record for each order date. | Reruns replace earlier failures. |
| Time gate | Filters that stop the query outside 11:30 to midnight, Monday to Saturday (JST). | Stops false alarms while the job may still be running. |
| Records detector | A Dynatrace detector that opens a problem for each row the query returns. | One row means one failed order date. |
