# Result

| Outcome | Detail |
|---|---|
| New file | `4-v7-test-extraction-validate.workflow.yaml`, 4 tasks, GET only |
| Group | From servicenow_enrichment when there is no group tag (`GROUP_ORDER`) |
| Environment | PRE recognised from `env` tag, namespace or `dt.security_context` |
| Offering | Environment-matched offering first |
| Validation | Task 4 verdict with PASS, WARN, FAIL per field; compares with enrichment, EXPECTED and INC30340215 |

## Next Steps

| Step | Why |
|---|---|
| Import and press Run | Tests P-260916863 without sending anything |
| Read `valid_choices.u_environment` | Confirms the real pre-production label; update `PREPROD_LABEL` if needed |
| Copy the sys_id for "Dynatrace JP" | Reference fields need a sys_id |
| Check `offering_candidates` | See if QA Platforms has a Pre-Production offering |
| Add `SERVICE_MAP` for AGPOCLOUDWEBNGINX if you know its real service | Avoid the QA Platforms default |
| When PASS, ask for OPEN v7 | Same fixes, with POST and PagerDuty back on |
