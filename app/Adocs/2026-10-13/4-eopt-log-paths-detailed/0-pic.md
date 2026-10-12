# eopt Log Paths In Detail Pic

## Decision tree

```
eopt stdout
 A collector → S3 → Splunk ✔
 B OneAgent App only → metrics, traces, host ✔ logs ✘
 C collector → Dynatrace forwarder ✘ (eopt not in pipeline)
 fix → add eopt-prod-axa-li-jp to forwarder → check fields → alerts 31, 34
```

## Data flow

```
container → node file → collector ─► S3 → Splunk ✔
                                  └► (missing) log-handler-dynatrace → ingest API → Grail
```
