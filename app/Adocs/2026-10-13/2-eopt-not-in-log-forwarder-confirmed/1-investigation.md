# eopt Not In Log Forwarder Confirmed Investigation

| Query | Result |
|---|---|
| Logs per dt.openpipeline.source, 1 hour | 7 sources, 134.53 GiB, oneagent 65,088,085 lines, /api/v2/logs/ingest 256,344 |
| eopt in host.name, k8s.pod.name, k8s.namespace.name, log.source, 24 hours | 0 records, 154.43 GiB |
| lower(host.name) starts with eopt, 24 hours | 0 records, 465.66 GiB |
| multilogforwarder namespaces, 1 hour | 11 namespaces, eopt not present, 3.57 GiB |
| Scan size note | Filtered queries scan less because Grail skips blocks that cannot match. Not a tenant issue. |
