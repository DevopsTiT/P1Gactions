# Glossary

| Term | What it means |
|---|---|
| DQL | Dynatrace Query Language. The text in the Data tab. |
| `fetch events` | Load Dynatrace events for the notebook timeframe. |
| `CUSTOM_INFO` | A custom event type. This tile ignores other types. |
| `application` | Field that names the application. This tile requires `agj-myaxa`. |
| `jobs` | Field the status rule searches. The tile looks for the text `NG :`. |
| `NG` | The status written when that text is found. |
| `OK` | The status written when the newest event does not contain that text. |
| `limit 1` | Keep one row. After the descending sort, that row is the newest event. |
| `takeFirst` | After a descending time sort, the first value in each application group is the newest one. |
| `last_seen` | Timestamp of that newest event. |
| 0 records | The filters matched nothing. The tile has no status to show. |
| Timeframe | The window on the result line. This run is 09:28:29–11:28:29. |
