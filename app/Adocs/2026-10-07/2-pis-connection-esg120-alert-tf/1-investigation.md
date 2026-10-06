# Investigation

| Checked | Finding |
|---|---|
| Search | index=claims host="CEAA20B8.prprivmgmt.intraxa" sourcetype=pis_defaultlog, regex errorCode ESG120 |
| Schedule | Last 5 minutes, cron */5, expires 24 hours |
| Trigger | Results > 0, Once, For each result, no throttle |
| Action | Send email, priority Normal (recipient not copied) |
| Log file | /IFDATA/DATA/PC/LOG/PISP2/pisp2.log |
