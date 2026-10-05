# Control-M Alerts V2 Glossary

| Term | What it means | Why you care |
|---|---|---|
| 複製 | Japanese for "copy" | Alerts with this suffix are duplicates someone made |
| Output results to lookup | Splunk action that writes search results into a CSV | Housekeeping, not a notification |
| ControlmRerunHistory.csv | CSV that remembers which reruns were already processed | Not needed in Dynatrace |
| `report_intro` | Terraform map with the opening text of each report email | Keeps the Splunk message wording |
| `default("")` | Jinja filter that prints nothing when a value is missing | Reports without MSG still get a clean subject |
| Inline table | Splunk option that puts results as a table in the email | Becomes one text line per row |
