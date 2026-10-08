# Investigation

| What was checked | Finding |
|---|---|
| Search | `index="batch_monitoring_logs" \| table _time _raw` |
| Schedule | Cron `0 8 * * *`, range Today, expires 24 hours |
| Trigger | Number of Results greater than 0 |
| Action | Send email to one person, priority Normal, subject `Splunk Alert: $name$` |
| Log source (from 10-07 screenshot) | `/app/splunk/var/log/splunk/datalake_transfer.log` |
