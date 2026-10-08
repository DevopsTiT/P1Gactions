# CCI Goal Management URL Check Glossary

| Term | What it means | Why you care |
|---|---|---|
| URL check | Jenkins job that calls a web page and records the HTTP code | Its code decides OK or NG |
| HTTP 200 | The page answered normally | Any 200 means OK |
| responsecode | Splunk name for the JSON `status` field | Read as `j[status]` in DQL |
| Last 2 runs | Splunk keeps only the two newest runs | Approximated by a 30-minute window |
| Add to Triggered Alerts | Splunk list of fired alerts | Dynatrace Problems list replaces it |
| PagerDuty Disable | No page, email only | `pagerduty.enabled = "0"` |
