# Control-M Abend Alert V2 Investigation

| What was checked | Finding |
|---|---|
| Alert | CTL-M アベンドアラートV2 |
| Description | Empty ("Optional") |
| Base search | `sourcetype=controlm_alert message="Ended not OK"` |
| eval | system, RUN_COUNT, JOB_CODE, HH, MM, SS |
| join | Left join on job_name with `sourcetype=controlm_def_ver_jobs` for cmd_line and owner |
| Schedule | Cron every minute, last 5 minutes |
| Trigger | More than 0 results, for each result |
| Throttle | On, by JOB_CODE, 6 minutes |
| Actions | Cut off in the screenshot |
| Log format | Unknown. Parse assumes key=value. |
