# Datalake Batch Result Glossary

| Term | What it means | Why you care |
|---|---|---|
| Scheduled workflow | Dynatrace automation that runs on a cron schedule | Right tool for daily reports |
| Detector | Rule that opens a problem when a number crosses a threshold | Wrong tool here, it would page people |
| `table _time _raw` | Splunk command that shows time and the raw line | Becomes `fields timestamp, content` |
| "Today" time range | From midnight to the run time | At 08:00 JST that is the last 8 hours |
| `@d` alignment | DQL rounds time to the start of a day in UTC | UTC midnight is 09:00 JST, so it would break an 08:00 run |
| `{% for %}` loop | Jinja template loop in the email body | Prints one log line per row |
| `else = "SKIP"` | Task is skipped when its condition is false | No email when there are no lines |
