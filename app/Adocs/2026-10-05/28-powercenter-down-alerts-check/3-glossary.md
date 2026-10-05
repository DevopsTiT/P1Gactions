# PowerCenter Down Alerts Glossary

| Term | What it means | Why you care |
|---|---|---|
| PowerCenter | Informatica's batch data integration (ETL) server | The service this alert watches |
| ISP_MASTER_ELECT_LOCK | Text in PowerCenter logs that the team treats as "service down" | The only thing the search looks for |
| Overlapping window | Checking the last 15 minutes every 1 minute | The same line is counted many times, so emails repeat |
| Throttle | Splunk setting that mutes repeats for a period | Off here, so nothing stopped repeats |
| Detector | Dynatrace rule that runs a query on a schedule and opens a problem | Replaces the Splunk alert |
| Dealerting samples | Quiet minutes needed before the problem closes | 15 here, so one outage stays one problem |
| `dt.source_entity` | The entity the problem attaches to | Gives the standard flow host tags for routing |
| `caseSensitive: false` | Makes DQL `contains` ignore upper and lower case | Splunk ignores case by default |
