# Datalake Batch Result Investigation

| Field in screenshot | Value |
|---|---|
| Alert | Datalake_Batch Result |
| Description | Optional (empty) |
| Search | `index="batch_monitoring_logs" | table _time _raw` |
| Time range | Today |
| Cron | `0 8 * * *` |
| Trigger | Number of results greater than 0, once |
| Throttle | Off |
| Action | Send email to one person, Normal priority |

| Observation | Meaning |
|---|---|
| No filter, just a table | The output is the content, so it is a report |
| "Today" at 08:00 | Covers 00:00 to 08:00 JST |
| Single recipient | Spelling must be confirmed from the screenshot |
