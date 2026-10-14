# Glossary

| Term | What it means |
|---|---|
| DQL | Dynatrace Query Language. |
| Grail | Dynatrace data storage for logs. |
| `content` | The raw log line (Splunk `_raw`). |
| `timestamp` | Event time (Splunk `_time`). |
| `contains()` | Checks if text appears in a field. |
| `caseSensitive:false` | Makes `contains()` ignore upper and lower case. |
| `arrayRemoveNulls()` | Drops empty entries from a list. |
| `expand` | Turns one row with a list into one row per list item. |
| `formatTimestamp()` | Turns a timestamp into readable text. |
