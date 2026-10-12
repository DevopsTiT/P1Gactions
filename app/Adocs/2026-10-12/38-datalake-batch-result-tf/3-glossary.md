# Datalake Batch Result Glossary

| Term | What it means |
|---|---|
| Cron `0 8 * * *` | Run every day at 08:00. |
| Time range Today | From midnight until now. |
| `table _time _raw` | Splunk command showing only time and the raw line. |
| JST guard | Filter on the current Tokyo time so rows only exist in a set window. |
| `formatTimestamp` | DQL function that turns a time into text, here hour and minute in Tokyo time. |
| Identity field | Field deciding whether a row joins an existing problem. |
