# Glossary

| Term | What it means |
|---|---|
| SPL | Splunk query language. |
| DQL | Dynatrace query language. |
| Grail | Dynatrace data storage. |
| `content` | Full log line (Splunk `_raw`). |
| `timestamp` | Event time (Splunk `_time`). |
| `index` | Splunk storage area. Not in Dynatrace. |
| `sourcetype` | Splunk log format label. Not in Dynatrace. |
| `contains()` | Substring match. Case-sensitive by default. |
| `matchesPhrase()` | Whole-word match, case ignored. |
| `matchesValue()` | Wildcard pattern match, case ignored. |
| `parse` | Extract fields from text with a pattern. |
| `lookup` | Join another query's rows by a shared field. |
| `summarize` | Group and count (Splunk `stats`). |
| `makeTimeseries` | Chart over time (Splunk `timechart`). |
| `timeseries` | Read metrics. |
| Subsearch | Splunk inner search feeding the outer search. |
| Check query | Our helper query that shows where an app's name lives in Dynatrace. |
| Onboarding request | Ask the platform team to send an app's logs to Dynatrace. |
