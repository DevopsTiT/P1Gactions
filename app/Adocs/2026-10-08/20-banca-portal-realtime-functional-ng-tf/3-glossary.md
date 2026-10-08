# Banca Portal NG Glossary

| Term | What it means | Why you care |
|---|---|---|
| Real Time Check | Jenkins job that checks Banca Portal often | Its result decides OK or NG |
| Functional job | Jenkins job with detailed test cases | Grouped with the Real Time job under one project |
| build_report | JSON Jenkins writes per build | The log the detector reads |
| configuration lookup | Maps job name to application and pager_duty | Selects Banca Portal projects |
| Alert Status Manager | Splunk action that sends email and PagerDuty | Replaced by a Dynatrace workflow |
| pagerduty.enabled | Flag the workflow reads | "1" because PagerDuty is enabled |
