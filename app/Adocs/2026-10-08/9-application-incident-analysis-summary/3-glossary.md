# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Saved search (report) | A scheduled Splunk search with no alert action | Not every saved search needs a detector |
| `inputlookup` | Read a lookup table (CSV) in Splunk | The data source here |
| `outputlookup` | Write results into a lookup table | Other searches fill `monitor_logs` this way |
| `collect` | Save search results as events in another index | Builds the summary index |
| Summary index | An index of pre-computed results | Dynatrace does not need one; Grail queries are fast enough |
| `relative_time(now(),"-1d@d")` | Yesterday at 00:00 | Used to get yesterday's date |
| Grail lookup | A file uploaded to Dynatrace and read with `load` | Static; does not grow like a Splunk lookup |
| `dynatrace_document` | Terraform resource for dashboards and notebooks | Lets the dashboard live in Git |
| `countIf` | DQL count of rows matching a condition | Replaces `count(eval(...))` |
