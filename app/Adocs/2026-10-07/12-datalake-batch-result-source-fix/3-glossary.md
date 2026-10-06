# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Splunk index | A named storage bucket inside Splunk, like `batch_monitoring_logs` | Dynatrace has no indexes, so you cannot filter on this name. |
| source (Splunk) | The file the log line came from | Maps to `log.source` in Dynatrace. |
| sourcetype | A Splunk label for the log format | Not needed in DQL. |
| `log.source` | Dynatrace field holding the log file path | The most reliable filter for file-based logs. |
| OneAgent log ingest | Dynatrace agent setting that chooses which files to send | If the file is not listed, the detector sees nothing. |
| Records detector | Detector that opens a problem when the query returns rows | Works without `makeTimeseries`. |
| `alertIdentityFields` | The field that decides how many problems open | A constant `check` value means one problem per night. |
| UDM | The downstream data platform the batch sends files to | "sent to UDM successfully" is the success signal. |
