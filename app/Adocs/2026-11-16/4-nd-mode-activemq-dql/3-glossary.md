# Glossary

| Term | What it means |
|---|---|
| `head 1` | Keep the newest matching event and drop the rest. |
| `ACTIVEMQMODE` | The mode written in the line, inside quotes. The newest row in this job is `A`. |
| `ND_Mode_DC1` | The Splunk source name on all 1,486 events. |
| `log.source` | The Dynatrace field used here for that source name. |
| `limit 1` | The DQL step that keeps one row after the newest-first sort. |
