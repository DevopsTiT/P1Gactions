# Result

| Step | Action |
|---|---|
| 1 | Add `environment-api:problems:read` in the workflow Authorization settings |
| 2 | Import the v2 YAML and Run |
| 3 | Check `servicenow_enrichment.match_method` |
| 4 | If still not found, run 3.sh lines 1–6 to see how SILVA names the Oracle CI and which ALJ services exist |
| 5 | Put the correct service in `SERVICE_MAP` (for example `ALJ: "<exact name>"`) |
| 6 | Once correct, copy `snow_incident_payload` and `pagerduty_payload` logic into OPEN |
