# URL MyAXA Investigation

| What I checked | What I found |
|---|---|
| Sourcetype | text:jenkins, which is missing. |
| OK rule | job_result matches "OK". |
| NG rule | event=2 and no OK. |
| App filter | None in Splunk. |
| PagerDuty | Enable. |
