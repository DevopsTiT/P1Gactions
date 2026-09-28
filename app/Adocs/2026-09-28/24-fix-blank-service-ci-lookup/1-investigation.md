# Investigation

| What was checked | Finding |
|---|---|
| INC30339813 notes | Business service uk-sap-fscd-dev and default offering were computed; no SYSTEM_MAP match. |
| INC30339813 form | Business service, offering and CI blank; group Ops_Middleware_Monitoring_AXAJP filled. |
| Field changes | Single entry at create; no second entry, so the sys_id PATCH did not run. |
| Seq 20 lookup code | Accepted a sys_id only when exactly one record matched. |
| Seq 20 CI code | Sent the FQDN as a plain name. |
| Summary JSON | managementZones empty; severity "3". |
| Placeholders | PD URL, dashboard URL and L3 group still placeholders. |
