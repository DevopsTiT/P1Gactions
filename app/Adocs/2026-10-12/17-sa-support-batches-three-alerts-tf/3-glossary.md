# Sa Support Batches Glossary

| Term | What it means |
|---|---|
| Records detector | A Dynatrace rule that runs DQL every minute and opens a problem when rows come back. |
| Absence alert | An alert that fires when an expected log line is missing. |
| `summarize count()` | Turns all matching lines into one row holding the number of lines. Returns 0 when nothing matched. |
| Identity field | The field that decides whether a new row belongs to an existing problem. |
| JST guard | Filters on Tokyo weekday and time so the detector only reports in a chosen window. |
| `formatTimestamp` | DQL function that turns a time into text, with an optional timezone. |
| Scheduled workflow | A Dynatrace workflow started by a clock trigger instead of a problem. |
| Cron `30 8 * * 1-5` | 08:30, every day of the month, every month, Monday to Friday. |
