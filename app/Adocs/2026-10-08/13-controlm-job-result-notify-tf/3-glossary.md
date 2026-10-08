# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Control-M | Batch job scheduler | Source of the job status logs |
| Abend (アベンド) | Abnormal end of a job | The alert follows up on abends |
| 正常終了 | Ended normally | The job recovered |
| 異常終了 | Ended abnormally | The job failed again |
| order_id | Control-M ID of one ordered job | Part of the run ID |
| isn | Control-M internal sequence number | With order_id, identifies one run |
| `dedup` | Keep one row per value | One row per run |
| `join type=left` | Attach matching rows from another search | Replaced by DQL `lookup` with a subquery |
| 対応方法 (Method) | How to respond, from controlm_addresslist.csv | Shown in the 異常終了 title |
| Throttle | Suppress repeat alerts for a time | Here 10 minutes per job |
