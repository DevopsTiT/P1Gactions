# MyAXA NG State Glossary

| Term | What it means | Why you care |
|---|---|---|
| NG | "No good", any job_result that is not SUCCESS | The state the alert watches |
| External Check | Jenkins job that tests MyAXA from outside | Its result is the health signal |
| Login_Check | The MyAXA login-check job | One of the two problems |
| Function_Check | The MyAXA functional check job | The other problem |
| MYAXA_Monitoring.csv | Splunk lookup holding the current result | Replaced by the newest log line in Dynatrace |
| maintenance_window | Lookup of planned maintenance periods | Stops alerts during planned work |
| collectArray / arrayLast | Collect values into a list, take the last one | Gets the newest old NG result, skipping empty rows |
| takeLast | Last value in record order | Newest run after `sort timestamp asc` |
| Records detector | Each returned row is a violation | One row per JobName means one problem per check |
