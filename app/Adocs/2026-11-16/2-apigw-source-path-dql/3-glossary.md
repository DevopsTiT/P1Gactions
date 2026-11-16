# Glossary

| Term | What it means |
|---|---|
| `source` in Splunk | The log file path. Here it is `/opt/softwareag/log/1015/apigw5500/server.log`. |
| `log.source` | The Dynatrace field that stores that file path. |
| `status: FAILURE` | The text inside the log line. Splunk copies it into the Status field. |
| 101 | The event count for host WPALJA21BC from 09:00 to 09:13. |
| `from: now()-15m` | A new 15-minute window. It will not return 101 unless you run it during that same job. |
