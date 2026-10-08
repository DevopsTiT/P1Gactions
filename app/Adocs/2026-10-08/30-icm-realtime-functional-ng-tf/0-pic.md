# Claims ICM Detector Pic

```
Splunk ICM alert
 jenkins_statistics template → FCR query with "Claims ICM"
 actions = Triggered Alerts only → pagerduty "0", medium
 want paging? → pagerduty "1", high
 lookup missing "Claims ICM"? → never fires
```

```
Jenkins logs → filter job_duration, drop audit_trail → lookup application
  → rt_fails >= 2, rt_oks == 0 → problem → SUCCESS closes it
```
