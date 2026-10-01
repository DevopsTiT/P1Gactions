# Investigation

| What was checked | Evidence |
|---|---|
| Graph | preview-pagerduty below preview-silva-incident = serial version |
| open_v7_would | SKIP (maintenance is on) |
| Tags | AGO_Maintenance:True and Test_Maintenance:True in entity_tags |
| Code | Task 1: event field first, then tag ago_maintenance = true |
| Payload | All keys filled; reference fields are sys_ids |
| Service vs offering | 03bd24ce... vs 3d62b88e... (different) |
| PD body | dedup_key, summary, source, severity OK; links still SILVA placeholder (old version) |
