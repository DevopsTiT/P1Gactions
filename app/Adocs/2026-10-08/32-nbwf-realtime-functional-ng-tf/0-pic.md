# NBWF Detector Pic

```
Splunk NBWF Real Time alert
 jenkins_statistics template → FCR query with "NBWF"
 Alert Status Manager → severity high
 PagerDuty Enable? → pagerduty "1" | unknown → "0"
 lookup missing "NBWF"? → never fires
```

```
Jenkins logs → filter job_duration, drop audit_trail → lookup application
  → rt_fails >= 2, rt_oks == 0 → problem → SUCCESS closes it
```
