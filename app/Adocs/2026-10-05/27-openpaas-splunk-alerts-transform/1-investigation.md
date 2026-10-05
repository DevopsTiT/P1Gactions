# Investigation

| What was checked | Finding |
|---|---|
| Alert 1 | Egress proxy IP absence check every 15 minutes, email High |
| Alerts 2, 4, 5 | Same Emma BE to ESG timeout search, > 20 in 5 minutes, throttle 60 seconds |
| Alert 3 | PIS on CEAA2058, regex errorCode ESG120, email Normal |
| Alerts 6, 7 | eopt namespace, backend text level and frontend JSON level, hourly, email Normal |
| Secrets | PagerDuty key visible in screenshot 5, not copied |
| Mapping | Splunk index and sourcetype have no direct Dynatrace field; guessed and marked CONFIRM |
