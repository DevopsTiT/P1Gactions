# Emma BE ESG Timeout Investigation

| What was checked | Finding |
|---|---|
| Alert | Prod_Life_Emma_EmmaBETmeoutToESGProduction_High |
| Description | Monitors ESG calls from Emma BE (OpenPaaS) to ESG (CoreIT) for timeouts. |
| Search part A | `index="myaxabackend-prod-axa-li-jp" api-jp-cert.corp.intraxa AND "java.net.SocketTimeoutException"` |
| Search part B | `append [search index="apigw_syslog" sourcetype=apigw_syslog_prod "Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa"]` |
| Time range | Last 5 minutes, cron every 5 minutes |
| Trigger | More than 20 results, once |
| Throttle | On, 60 seconds |
| Actions | Triggered alert High, PagerDuty, send email |
| Host field | 17 values, all myaxabackend pod names |
| Source | S3 log forwarder paths (axa-li-jp-logforwarders-prod) |
| Matches | 152 events from 9/12 to 10/12 |
