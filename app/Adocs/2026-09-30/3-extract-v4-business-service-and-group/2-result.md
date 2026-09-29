# Result

| Step | What to do |
|---|---|
| 1 | Upload `3-extract-v4-business-service-and-group.workflow.yaml` in Dynatrace Workflows |
| 2 | Add `silvastg.service-now.com` to the External requests allowlist, if not done |
| 3 | Add `environment-api:problems:read` in Workflow Settings → Authorization |
| 4 | Press Run. It uses the Oracle sample event. |
| 5 | Open the display-result task and read `snow_required` first |
| 6 | If `business_service.from` is "not found", read `lookup.service_candidates` |
| 7 | Put the correct name into `SERVICE_MAP` and run again |
| 8 | When `ready_for_snow` is true, copy the same group and service logic into OPEN |

## Open items

| Item | Owner |
|---|---|
| Confirm ACCEPTANCE maps to "Integration / Test" | SILVA team |
| Confirm the business service for trigram ALJ | App or DB team |
| Real DNS domains for the DOMAINS list | Infra team |
| Do not push app/Adocs, because the YAML holds the password | You |
