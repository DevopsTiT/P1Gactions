# Investigation

| Checked | Evidence |
|---|---|
| Alert name | Datalake_Batch Result, same as seq 29 |
| Search | `index="batch_monitoring_logs" \| table _time _raw` |
| Time range and cron | Today, `0 8 * * *` |
| Trigger | Results > 0, once |
| Action | Email masayuki.yasuda@axa.co.jp, Normal |
| Seq 29 differences | No provider block; UTC timestamps in the email |
