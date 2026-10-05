# Glossary

| Term | What it means |
|---|---|
| DQL | Dynatrace Query Language, used in Notebooks and Dashboards to query Grail |
| Grail | Dynatrace's data store for logs, events, metrics and spans |
| bucket | A storage area in Grail with its own retention, closest thing to a Splunk index |
| `fetch logs` | Starts a DQL query on log records |
| `filter` | Keeps only matching records, like a Splunk search filter |
| `summarize` | Groups and counts, like Splunk `stats` |
| `lookup` | Joins results of a subquery onto the current rows |
| `data record` | Builds rows by hand, like Splunk `makeresults` |
| `coalesce` | Returns the first non-empty value |
| `log.source` | The attribute that says where a log came from |
| syslog | A standard protocol network devices use to send logs |
