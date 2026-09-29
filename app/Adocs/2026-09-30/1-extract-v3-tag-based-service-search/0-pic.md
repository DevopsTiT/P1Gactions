# Extract v3 Picture

```
tags → search terms: group, dbType, envTag, regionPrefix, trigram, host, domain
 ├─ A SERVICE_MAP / service tag → exact name
 ├─ B host name / fqdn.domain → CI → business_service field → svc_ci_assoc → cmdb_rel_ci
 ├─ C search 1 group
 │    search 2 db + env
 │    search 3 db + region
 │    search 4 trigram
 │    search 5 technical db + env
 │    → merge → score → best (≥ 5, clear lead) or top 10 candidates
 ├─ D offering by env
 └─ E group check
 → display-result: pic 5 layout + decision + SNOW / PD payload preview
```
