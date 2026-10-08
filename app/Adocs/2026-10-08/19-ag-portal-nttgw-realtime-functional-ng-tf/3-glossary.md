# AG Portal NTTGW NG Glossary

| Term | What it means | Why you care |
|---|---|---|
| Real Time Check | Jenkins job that checks AG Portal NTTGW often | Its result decides OK or NG |
| Functional job | Jenkins job with detailed test cases | Grouped with the Real Time job under one project |
| build_report | JSON Jenkins writes per build | The log the detector reads |
| ABORTED / FAILURE | Build results Splunk excludes | Kept excluded to match Splunk |
| streamstats index<=2 | Splunk keeps the last 2 runs per job | Approximated by 2+ NG in the window |
| Alert Status Manager | Splunk action that sends email and PagerDuty | Replaced by a Dynatrace workflow |
| pagerduty.enabled | Flag the workflow reads | "1" here because PagerDuty is enabled |
| Macro | Reusable Splunk search snippet | Maintenance logic lives in one; not migrated |
