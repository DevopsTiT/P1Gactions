# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Control-M | A batch job scheduler that runs and tracks jobs | Its job status logs feed all these alerts |
| `order_id` | Control-M's ID for one run of a job | Used to give every run its own problem |
| `odate` | Control-M order date (the business date of the run) | Used in the old reports |
| Ended OK | Control-M status for a successful run | Absence of it means the job did not succeed |
| Ended not OK | Control-M status for a failed run (abend) | Triggers `job_abend` |
| Abend | Abnormal end, a failed job | The main thing to alert on |
| Records detector | Opens a problem when the query returns rows | Replaces makeTimeseries and workflows here |
| Absence alert | Fires when an expected event did not happen | Replaces the daily report emails |
| `countIf` | DQL count of rows matching a condition | Counts only Ended OK rows |
| Lookback window | How far back the query reads (`from:now()-26h`) | Must cover the job's normal gap between runs |
