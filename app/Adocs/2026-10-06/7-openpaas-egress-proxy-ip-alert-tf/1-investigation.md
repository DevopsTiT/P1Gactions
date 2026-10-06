# Investigation

| Checked | Finding |
|---|---|
| Search | index=apigw_syslog sourcetype=apigw_syslog_prod /maam/* *52.76.125.86* OR *54.179.120.88* then stats count, where count <= 0 |
| Schedule | Last 15 minutes, cron */15, expires 24 hours |
| Trigger | Results > 0, Once, For each result, no throttle |
| Action | Email only, priority High |
| Log source | host EEAA2015.ppprivmgmt.intraxa, /SYSLOG/APIGW/prod/local4.log |
