# Investigation

| Checked | Finding |
|---|---|
| Search part 1 | index="myaxabackend-prod-axa-li-jp" api-jp-cert.corp.intraxa AND "java.net.SocketTimeoutException" |
| Search part 2 (append) | index="apigw_syslog" sourcetype=apigw_syslog_prod "Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa" |
| Schedule | Last 5 minutes, cron */5, expires 24 hours |
| Trigger | Results > 20, Once, For each result, throttle 60 seconds |
| Action | Email only, priority High |
| Backend log source | host myaxabackend-*, s3://axa-li-jp-logforwarders-prod/... |
| Volume | 6 events in about 24 hours |
