# Portals AMP Not In Dynatrace Investigation

| Evidence | Finding |
|---|---|
| Dynatrace check query | 0 records, 24 hours, 171.29 GiB scanned. |
| Fields searched | host.name, k8s.pod.name, k8s.container.name, log.source. |
| Case | Ignored, so spelling case is not the cause. |
| Splunk | 75 events per hour from `portals-amp-backend-...` pods. |
| Splunk source | `s3://axa-gi-jp-logforwarders-prod`. |
| Similar case | eopt on 2026-10-13: S3 only, not in Dynatrace forwarder. |
| Still to rule out | Other field names (check A) and bucket permissions (check B). |
