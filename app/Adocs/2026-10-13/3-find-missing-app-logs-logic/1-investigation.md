# Find Missing App Logs Logic Investigation

| Step | Question | Query idea | eopt evidence |
|---|---|---|---|
| 1 | Platform healthy? | Count logs by dt.openpipeline.source | 134 GiB per hour, 65 M OneAgent lines |
| 2 | App exists? | fetch dt.entity.host | 15 hosts |
| 3 | Logs anywhere? | App name in every field, ignore case, 24 h | 0 records |
| 4 | Sibling path? | /api/v2/logs/ingest by log.source | multilogforwarder-log-handler-dynatrace |
| 5 | App on path? | Forwarder logs by namespace | 11 namespaces, eopt missing |
| 6 | Logs elsewhere? | Splunk source | S3 axa-li-jp-logforwarders-prod |
