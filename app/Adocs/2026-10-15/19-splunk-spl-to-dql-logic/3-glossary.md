# Splunk To DQL Glossary

| Term | What it means |
|---|---|
| SPL | Splunk Processing Language. |
| DQL | Dynatrace Query Language. |
| DPL | Dynatrace Pattern Language, used in `parse`. |
| `_raw` | Splunk's full log line. DQL calls it `content`. |
| `_time` | Splunk's event time. DQL calls it `timestamp`. |
| Auto-extraction | Splunk making fields from `key=value` text without being asked. |
| Subsearch | A Splunk query in `[ ]` whose results feed the outer query. |
| `format` | Splunk command that turns subsearch rows into search words. |
| `matchesPhrase` | DQL whole-word match that ignores case. |
| `contains` | DQL substring match, case-sensitive by default. |
| `lookup` | DQL join of rows from a second query on a shared field. |
| Greedy | A pattern piece that takes as many characters as it can. |
