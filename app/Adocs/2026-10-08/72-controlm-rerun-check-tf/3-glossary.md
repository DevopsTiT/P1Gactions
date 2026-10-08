# Control-M Rerun Check Glossary

| Term | What it means | Why you care |
|---|---|---|
| リラン (rerun) | Running a failed job again. | This alert reports reruns that succeeded. |
| Abend | Abnormal end of a job. | A rerun only counts if the run abended first. |
| order_id | The Control-M ID of one ordered job run. | Splunk groups all snapshots of a run by it. |
| JOB_CODE | "Rerun:" + job name + abend time. | Splunk's history key, and the Dynatrace problem identity. |
| ControlmRerunHistory.csv | Splunk lookup of reruns already mailed. | Not needed in Dynatrace. |
| append | Splunk command that adds rows from another search. | Replaced by a lookup on order_id. |
| WORKTIME | Time from the abend to the final end. | How long recovery took. |
| RUNTIME | Time from the rerun start to its end. | Compare with AVGRUNTIME to spot slow reruns. |
