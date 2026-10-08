# IWFM Three Alerts Result

| Detector | Window | Fires when | Severity | PagerDuty |
|---|---|---|---|---|
| eip_iwfm_eip006_service_failure | 1 minute | failures > 2 | high | "0" |
| compass_iwfm_report_exception | 5 minutes | exceptions > 15 | medium | "0" |
| iwfm_errors | 1 hour | errors > 0 | medium | "0" |

Before apply, run the check queries, and destroy 10-05 seq 32 if it was applied.
