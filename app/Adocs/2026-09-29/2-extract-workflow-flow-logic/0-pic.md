# Flow Logic Picture

```
Trigger CREATED / Run
 ▼
T1 extract: event or SAMPLE_EVENT → tags → parse → ago/other → hints → dynatrace_alert
 ▼ (OK)
T2 lookup (GET only)
   A service tag / SERVICE_MAP → cmdb_ci_service ── found → enrichment
   B host / entity → cmdb_ci → svc_ci_assoc → cmdb_ci_service ── found → enrichment
   none → found:false
   C group tag → sys_user_group
 ▼ (OK)
T3 display → JSON → Log + Result
```
