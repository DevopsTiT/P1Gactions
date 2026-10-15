# Dynatrace Dummy Data Glossary

| Term | What it means |
|---|---|
| `data` command | Makes fake records inside a DQL query. Nothing is stored. |
| `record(...)` | One fake row with the fields you list. |
| Grail | Dynatrace storage for logs, metrics and events. |
| Ingest | Sending data into Dynatrace to be stored. |
| Log ingest API | `POST /api/v2/logs/ingest`, accepts JSON log records. |
| Metrics ingest API | `POST /api/v2/metrics/ingest`, accepts metric lines as text. |
| API token | Secret key for calling the API. Keep it in an environment variable. |
| `logs.ingest` | Token scope that allows sending logs. |
| `metrics.ingest` | Token scope that allows sending metrics. |
| Retention | How long stored data is kept. |
| Test tenant | A separate Dynatrace environment used only for testing. |
