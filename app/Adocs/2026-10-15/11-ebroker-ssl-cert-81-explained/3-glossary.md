# Ebroker SSL Cert 81 Glossary

| Term | What it means |
|---|---|
| SSL/TLS certificate | Proves a server's identity for HTTPS. It has an end date. |
| ebroker | The broker API server that partner channels call for quotes. |
| Lookup table | A CSV stored in Splunk and read by searches. |
| `makeresults` | Splunk command that creates an empty row. |
| `relative_time` | Splunk function that adds or subtracts time from a timestamp. |
| `load` | DQL command that reads a lookup file from Grail. |
| Synthetic HTTP monitor | Dynatrace scheduled URL check, including certificate expiry. |
| Private Synthetic location | An ActiveGate inside the company network that runs Synthetic monitors against internal hosts. |
