# eopt Hosts Exist Logs Missing Investigation

| Check | Result |
|---|---|
| `fetch dt.entity.host` starts with eopt, 7 days | 15 hosts |
| Logs `host.name` starts with eopt, 24 hours | 0 records, 149.72 GiB scanned |
| Logs via `entityName(dt.entity.host)`, 1 hour | 0 records, 156.23 GiB scanned |
| Logs for eoptsystemapi-564c45bd9f-jqqtl, 1 hour | 0 records |
| Logs grouped by cost fields, 1 hour | 0 records |
| Level parse on backend pods, 1 hour | 0 records |
| Splunk source for eopt | S3 path axa-li-jp-logforwarders-prod |
| Host monitoring type | App only, OpenShift |
