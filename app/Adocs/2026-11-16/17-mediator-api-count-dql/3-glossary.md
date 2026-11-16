# Glossary

| Word | What it means |
|---|---|
| `eip_mediator_serverlog` | The Splunk sourcetype for these gateway logs. |
| `log.source` | The Dynatrace field that holds the file path. |
| `host.name` | The Dynatrace field that holds the gateway host name. |
| `API` | The API name inside the log line, after the text `API:`. |
| `Count of API` | How many log lines Splunk counted for that API. |
| `ALL` | The same API counted on every host together. |
| `limit=101` | Splunk keeps at most 101 API names. This search currently has 34. |
| `-60m@m` | The dashboard time start. Sixty minutes ago, on the minute. |
