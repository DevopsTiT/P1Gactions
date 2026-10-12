# Glossary

| Term | What it means | Why you care |
|---|---|---|
| BRE | Business rules engine (InnoRules). | The system being watched. |
| Cron hour field `1-5` | Run only when the hour is 1 to 5. | Limits the alert window. |
| `getHour()` | Hour of a timestamp in UTC. | Rebuilds the window. |
| `formatTimestamp` with `timezone` | Formats time in a chosen timezone. | JST version of the window. |
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces the scheduled alert. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"1"` here. |
