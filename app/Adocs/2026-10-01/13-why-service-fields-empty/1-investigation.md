# Investigation

| What was checked | Evidence |
|---|---|
| V6 output (run twice) | `{"business_service": "", "service_offering": ""}` |
| u_so_display_name | Requested but not in output, so the key is unknown or hidden |
| First command keys[] | Output not visible in the screenshot |
| Form screenshot earlier | Business service and Service Offering both "Third Party Services Monitoring Application" |
| Table API behavior | Unknown keys are dropped; empty or unreadable fields come back as "" |
| Earlier workflow result | reference_incident found: true on silvastg, so the incident exists on stg |
