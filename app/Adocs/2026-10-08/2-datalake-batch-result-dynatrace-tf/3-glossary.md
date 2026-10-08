# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Scheduled alert (Splunk) | Search that runs on a cron time | Dynatrace detectors run every minute instead |
| Time range Today | Splunk reads from midnight to now | Replaced by the detector's 2-hour lookback |
| Trigger Once | One email per run, not one per row | Matches identity `check` |
| Expires | How long Splunk keeps the triggered alert | Dynatrace closes the problem when rows age out |
| Records detector | Opens a problem when the query returns rows | No `makeTimeseries` needed |
| `log.source` | Log file path in Dynatrace | Replaces the Splunk index name |
