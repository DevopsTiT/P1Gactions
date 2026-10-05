# Glossary

| Term | What it means |
|---|---|
| OneAgent | The Dynatrace agent installed on the VM; it collects metrics and logs |
| Log ingest rule | A setting that tells OneAgent which logs to send, such as the Windows Application log |
| Windows event ID | A number that identifies a kind of Windows event; 258 here |
| OpenPipeline | Dynatrace's processing pipeline for incoming data; it can raise events from logs |
| Davis event | An event Dynatrace's AI engine (Davis) uses to open or update problems |
| CUSTOM_ALERT | An event type that opens a problem with a custom title |
| Anomaly Detection app | Lets you alert on a DQL timeseries with a threshold |
| Sliding window | The number of recent minutes checked for a threshold breach |
| dt.source_entity | The entity (here the host) an event belongs to; it carries the host's tags |
| eventcreate | A Windows command that writes a test event into an event log |
