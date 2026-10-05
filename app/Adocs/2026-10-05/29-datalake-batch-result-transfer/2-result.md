# Datalake Batch Result Result

| Outcome | Detail |
|---|---|
| Resource | 1 `dynatrace_automation_workflow`, `Prod_Datalake_BatchResult_Normal` |
| Schedule | 08:00 daily, Asia/Tokyo |
| Query window | `from:now()-8h` (midnight JST) |
| Email | Sent only when there is at least 1 line, capped at 500 lines |
| Paging | None, on purpose |
| To confirm | Field for `index="batch_monitoring_logs"` and recipient spelling |
