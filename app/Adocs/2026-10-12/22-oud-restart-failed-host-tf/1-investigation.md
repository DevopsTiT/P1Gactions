# OUD Restart Failed Investigation

| What was checked | Finding |
|---|---|
| Alert | OUD restart failed |
| Search | `index=ods sourcetype=oud_service failed` |
| Time range | Last 24 hours |
| Cron | Looks like `1 4 * * *` (daily 04:01). Blurry, please confirm. |
| Trigger | Number of results greater than 0, once |
| Throttle | Off |
| Actions | Triggered alert High, PagerDuty, send email |
| index=ods hosts | One: WPALJA2162.prprivmgmt.intraxa, 346,670 events, 100% |
| Sources | 4, including `/opt/oracle/oud/asinst_1/OUD/logs/errors` |
| Sourcetypes | 2: `odu_errorlog` and `oud_service` |
| Secrets | None visible. |
