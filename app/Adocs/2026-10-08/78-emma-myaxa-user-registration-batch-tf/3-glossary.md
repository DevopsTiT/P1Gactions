# Emma MyAXA User Registration Batch Glossary

| Term | What it means | Why you care |
|---|---|---|
| CHDR010M | The Control-M batch that registers MyAXA users for emma. | This alert watches it. |
| emma | The system that receives the registered users. | A failed batch means users are not registered. |
| dedup job_name | Splunk keeps only the newest record for the job. | The detector does the same with `sort` and `takeLast`. |
| Ended OK | Control-M status for a successful run. | Anything else opens a problem. |
| odate | Control-M order date. | Used as identity, so each day gets its own problem. |
| Time gate | A filter that only lets the query return rows from 06:00 JST. | Avoids alerts before the batch should have finished. |
| Records detector | A Dynatrace detector that opens a problem for each row the query returns. | One row means one failed run. |
