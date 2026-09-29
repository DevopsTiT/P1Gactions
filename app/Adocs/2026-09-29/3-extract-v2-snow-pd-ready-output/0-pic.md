# Extract v2 Picture

```
event → extract (tags, hints, dynatrace_alert + env label)
      → lookup-silva (GET)
           A SERVICE_MAP / service tag
           B host exact → host. starts with → DB name contains → svc_ci_assoc → cmdb_rel_ci
           C trigram contains (1 match) else candidates
           D offering by env    E tag group
      → display-result
           dynatrace_alert + servicenow_enrichment (pic 5)
           decision (create? group env)
           snow_incident_payload + pagerduty_payload (preview, not sent)
```

```
first run
 ├─ tags             OK
 ├─ group            OK
 ├─ CI lookups       0 matches      → v2 wider CI search, SERVICE_MAP if still none
 └─ Problems API     scope missing  → add environment-api:problems:read
```
