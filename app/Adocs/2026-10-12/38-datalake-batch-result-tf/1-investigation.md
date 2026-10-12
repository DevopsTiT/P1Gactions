# Datalake Batch Result Investigation

| What was checked | Finding |
|---|---|
| Alert | Datalake_Batch Result |
| Description | Empty ("Optional") |
| Search | `index="batch_monitoring_logs" \| table _time _raw` |
| Schedule | Cron `0 8 * * *`, time range Today |
| Trigger | More than 0 results, once |
| Throttle | Off |
| Action | Email only, Normal. Recipient not copied. |
| Hosts | ceaa20BD, CEAA20BE, CEAA2101 (.prprivmgmt.intraxa) |
| Source | /app/splunk/var/log/splunk/datalake_transfer.log |
| Batch time | About 02:00:43 JST |
| Failure seen | Failed to delete Data LINEBOT.csv (2026/10/11) |
