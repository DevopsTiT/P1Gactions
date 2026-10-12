# PIS OpenPaaS ESG120 Glossary

| Term | What it means |
|---|---|
| PIS | Claims batch system writing pisp2.log. |
| OpenPaaS | Platform the PIS batch sends requests to. |
| ESG120 | Error code meaning Routing failed. |
| `regex _raw` | Splunk filter on the raw event text with a regular expression. |
| `host.name` | Dynatrace field with the server name. |
| `log.source` | Dynatrace field with the file path. |
| Records detector | DQL query run every minute that opens a problem when rows return. |
| Identity field | Field deciding whether a row joins an existing problem. |
