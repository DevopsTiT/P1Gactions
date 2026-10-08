# Investigation

| What was checked | Finding |
|---|---|
| Alert search | `[HTTP Monitor]` lines from `jenkins_console`, last 2 runs per check, NG when not 200 |
| Schedule | Every minute, Last 15 minutes |
| Lookup | `configuration` maps job_name to application (and pager_duty) |
| Macros | `check_maintenance_window`, `add_alert_info`; definitions not visible |
| Index content | 2 million events; host ceaa2099; sources are Jenkins job console paths |
| Earlier version | 2026-10-05 seq 34 with makeTimeseries |
