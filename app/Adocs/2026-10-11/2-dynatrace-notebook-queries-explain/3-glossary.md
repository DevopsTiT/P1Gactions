# Dynatrace Notebook Queries Glossary

| Term | What it means | Why you care |
|---|---|---|
| Notebook | Dynatrace page for running DQL cell by cell. | Where these queries live. |
| DQL | Dynatrace Query Language. | All four cells use it. |
| timeseries | Reads a metric as a line over time. | Cells 1 and 2. |
| fetch | Reads records such as logs or entities. | Cells 3 and 4. |
| Process group | All copies of the same process, like one service. | Cell 1 filter. |
| Process group instance | One running copy on one host or pod. | Cell 2 field. |
| Entity ID prefix | The start of an ID, like HOST- or PROCESS_GROUP-. | Tells you the type; a mismatch gives 0 records. |
| interval | Size of each time bucket. | Long ranges get big buckets that hide spikes. |
| loglevel | The level written in the log line. | Cell 3 filter. |
| status | The level Dynatrace works out for the log. | Safer filter when loglevel is missing. |
| Qualys agent | A security scanning agent on servers. | Source of most cell 3 errors. |
| Davis CoPilot | Dynatrace AI that writes DQL from a sentence. | Wrote cells 3 and 4; always read its query. |
| lookup | Joins fields from another query on a key. | Cell 4 adds host names. |
| belongs_to | The relationship from a process to its host. | Cell 4 host ID. |
| summarize | Groups rows, like Splunk stats. | Turns processes into a host list. |
