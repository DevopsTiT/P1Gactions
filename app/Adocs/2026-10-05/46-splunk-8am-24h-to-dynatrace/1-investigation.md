# Investigation

| Checked | Evidence |
|---|---|
| Splunk cron | `0 8 * * *` |
| Splunk expires | 24 hours |
| Detector schedule | Not supported; evaluates every minute |
| Detector close | By dealertingSamples, not by time |
| Workflow schedule | Supported with cron and time zone |
