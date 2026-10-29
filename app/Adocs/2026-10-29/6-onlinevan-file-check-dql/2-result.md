# Result

Read one row as a file heartbeat. OK means that path was seen in the logs during the last day. NG means it was not.

| Column | How to read it |
|---|---|
| source | The expected file path. |
| status | OK or NG. |
| last_date and last_time | When the newest matching log line arrived. |
| log_count | How many matching lines. Zero when the status is NG. |
