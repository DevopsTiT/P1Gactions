# Investigation

| What was checked | Finding |
|---|---|
| MQ alert search | `index=mq host="wpalja21b*.prprivmgmt.intraxa" *Connection timed out*` |
| MQ schedule and trigger | Every minute, Last 1 minute, results > 0, Once |
| MQ action | Email to infra list, priority Normal |
| MQ log file | `/var/mqm/qmgrs/MQSRVPROD/errors/AMQERR01.LOG` on WPALJA21B7 |
| AGPO alert search | sourcetype agportalapi, host agpo auth pods, BadRequest OR NotFound password responses |
| AGPO schedule and trigger | Every 5 minutes, Last 5 minutes, results > 1, Once, throttle 5 seconds |
| AGPO action | PagerDuty (integration key not copied) |
| AGPO log path | Pods, forwarded through S3 |
