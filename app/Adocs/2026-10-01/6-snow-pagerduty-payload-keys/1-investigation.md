# Investigation

| Source | Where the keys are built |
|---|---|
| OPEN v6 SNOW body | `display-result`, lines 762–780 |
| OPEN v6 PD body | `display-result`, lines 807–832; task 5 adds routing_key, snow_incident, snow_incident_url, links on lines 993–997 |
| CLOSE v6 SNOW body | `resolve-silva-incident`, lines 260–266 |
| CLOSE v6 PD body | `resolve-pagerduty`, lines 320–324 |
| TEST v7 SNOW body | `build-payload` task, same 16 keys, values from servicenow_enrichment |
