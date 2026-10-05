# Splunk VM Alert To Dynatrace Pic

```
Splunk: scheduled search every 5m → EventCode=258 found → alert action
Dynatrace: OneAgent reads event log → rule matches line → Davis event → problem → workflow

logs in Grail?            no  → add log ingest rule "Windows Application Log"
                          yes → pick rule type
any single line alerts?       → OpenPipeline Davis event
need count over a limit?      → Anomaly Detection static threshold
problem missing tags?         → set dt.source_entity to the host
test                          → eventcreate /T ERROR /ID 258 /L APPLICATION on the VM
```
