# Extract Tags Picture

## Decision tree

```
Problem CREATED (or Run → SAMPLE_EVENT)
 ├─ extract-event-tags: parse all tags → ago / other / hints → dynatrace_alert
 ├─ lookup-silva (GET only)
 │    service tag or SERVICE_MAP[trigram] → cmdb_ci_service
 │    else host/entity → cmdb_ci → svc_ci_assoc → cmdb_ci_service
 │    group tag → sys_user_group
 │    none → found:false, check steps
 └─ display-result → JSON like correctoutput.sh
```

## Data flow

```
event tags ─► hints ─► SILVA GET ─► servicenow_enrichment
     └──────────────► dynatrace_alert ──────┴─► display-result
```
