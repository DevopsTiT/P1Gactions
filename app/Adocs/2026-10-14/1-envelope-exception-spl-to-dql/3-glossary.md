# Envelope Exception SPL To DQL Glossary

| Term | What it means |
|---|---|
| `_raw` | Splunk full log line. DQL `content`. |
| `_time` | Splunk event time. DQL `timestamp`. |
| `mvappend` | Splunk list builder. |
| `arrayRemoveNulls` | DQL function that drops empty items from a list. |
| `match()` | Splunk regex test, case sensitive. |
| `contains()` | DQL text test. Case sensitive unless caseSensitive:false. |
| `strftime` | Splunk time to text. |
| `formatTimestamp` | DQL time to text. |
| `expand` | DQL: one row per list item. |
