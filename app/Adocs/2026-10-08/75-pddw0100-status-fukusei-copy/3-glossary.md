# PDDW0100 Claims Status Glossary

| Term | What it means | Why you care |
|---|---|---|
| PDDW | The overnight claims batch jobs in Control-M. | The business needs them finished by morning. |
| Snapshot | One activejobs log line showing a run's status at one moment. | A run has many; only the latest counts. |
| current_time | When the snapshot was taken. | Used to find the latest snapshot. |
| odate + order_id | Order date plus order ID: one run of one job. | The problem identity. |
| eventstats | Splunk command that adds a group statistic to every row. | Replaced by sort plus takeLast in DQL. |
| claims_job_list | Lookup with the Japanese name (処理) and schedule of each job. | Shown on the problem. |
| Time gate | The filter that only judges from 08:15 JST. | Stops alarms while the batch may still be running. |
