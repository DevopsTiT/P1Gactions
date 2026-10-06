# Investigation

| Checked | Finding |
|---|---|
| Search | index="batch_monitoring_logs", table _time _raw |
| Schedule | Today, cron 0 8 * * *, expires 24 hours |
| Trigger | Results > 0, Once, For each result |
| Action | Email to one person, priority Normal (not copied) |
| Data | 240 events in 30 days, 8 per night at about 02:00 |
| Failure | Failed to delete Data LINEBOT.csv every night |
