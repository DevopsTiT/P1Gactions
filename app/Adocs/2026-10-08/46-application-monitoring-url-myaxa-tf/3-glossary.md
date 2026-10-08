# URL MyAXA Glossary

| Term | What it means | Why you care |
|---|---|---|
| job_result | Result word in the HTTP Monitor line, for example OK | This alert judges OK or NG by it |
| event=2 | Both of the last 2 runs are present | NG needs two runs, not one |
| PagerDuty Enable | The Splunk action pages on-call | So pagerduty.enabled is "1" |
| enabled = false | Detector created switched off | Avoids surprise pages from a never-working alert |
