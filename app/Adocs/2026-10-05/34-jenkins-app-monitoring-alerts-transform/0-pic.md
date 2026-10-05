# Jenkins App Monitoring Picture

```
10 Splunk alerts
 URL, URL for MyAXA                 → detector 1 (per application + check, 15 min window)
 function + 7 "function for <app>"  → detector 2 (per application + test, 2 h window)

open:  2 failed runs, no OK run in window
close: first OK run (recovery)
page:  standard flow, skip when pagerduty.enabled = 0
```
