# Investigation

| Checked | Finding |
|---|---|
| Search | index=ods sourcetype=oud_service failed |
| Schedule | Last 24 hours, cron read as 1 4 * * * (daily 04:01), expires 24 hours |
| Trigger | Results > 0, Once, For each result, no throttle |
| Actions | High, PagerDuty, email (key not copied) |
| Host | WPALJA2162.prprivmgmt.intraxa, 100% of index ods |
| Path | /opt/oracle/oud/asinst_1/OUD/logs/ |
