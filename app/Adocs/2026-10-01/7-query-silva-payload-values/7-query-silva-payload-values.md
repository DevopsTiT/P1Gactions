# Query SILVA For Payload Values

## Decision Tree

```
Need a payload value?
 ├─ Want to copy a known-good ticket?        → Q1 GET INC30340215 (all keys, value + label)
 ├─ Reference field (needs sys_id)
 │    caller_id / u_on_behalf_of             → Q2 sys_user
 │    assignment_group                       → Q12 sys_user_group
 │    company                                → Q13 core_company
 │    business_service                       → Q10 cmdb_ci_service
 │    service_offering                       → Q11 service_offering (parent = service)
 ├─ Choice field (needs stored value)        → Q3–Q9 sys_choice (element = field name)
 ├─ Did OPEN already create a ticket?        → Q15 incident by correlation_id
 └─ PagerDuty key works?                     → Q16 trigger test, Q17 resolve test
```

## Short Takeaway

| Question | Answer |
|---|---|
| Fastest way | Q1: read INC30340215 with `sysparm_display_value=all`; it shows the stored value and the label for every key |
| Reference fields | Query the target table by name and copy `sys_id` |
| Choice fields | Query `sys_choice` with `name=incident^element=<field>`; send `value`, not `label` |
| Tool | `curl -G --data-urlencode` (avoids "URL rejected: Malformed input") |
| PagerDuty | No lookup API with a routing key; send a test trigger and resolve |
| Where | All one-liners in `7.sh`; set `SNOW_AUTH` first |

## Summary

SILVA's Table API answers every open question about the payload. Read one good incident to see real values, look up sys_ids for reference fields, and list `sys_choice` rows for drop-downs. For PagerDuty, the only way to check the routing key is a test trigger followed by a resolve with the same `dedup_key`.

## Setup (once per terminal)

```bash
export SILVA="https://silvastg.service-now.com"
export SNOW_AUTH='Tech_DynatraceJP_WS:<password>'
```

## Query Per Payload Key

| # | Answers this key | Table | `sysparm_query` | Copy this from the result |
|---|---|---|---|---|
| Q1 | All keys at once | `incident` | `number=INC30340215` | `value` and `display_value` per field |
| Q2 | `caller_id`, `u_on_behalf_of` | `sys_user` | `nameLIKEDynatrace^ORuser_nameLIKEDynatrace` | `sys_id` of Dynatrace JP |
| Q3 | `u_environment` | `sys_choice` | `name=incident^element=u_environment^inactive=false` | `value` for the PRE label |
| Q4 | `contact_type` | `sys_choice` | `name=incident^element=contact_type^inactive=false` | `value` of Event |
| Q5 | `category` | `sys_choice` | `name=incident^element=category^inactive=false` | `value` of Other |
| Q6 | `subcategory` | `sys_choice` | `name=incident^element=subcategory^inactive=false^dependent_value=other` | `value` of Other under category other |
| Q7 | `impact` | `sys_choice` | `name=incident^element=impact^inactive=false` | `value` of 4 - Low |
| Q8 | `urgency` | `sys_choice` | `name=incident^element=urgency^inactive=false` | `value` of 4 - Low |
| Q9a | `state` (CLOSE) | `sys_choice` | `name=incident^element=state^inactive=false` | `value` of Resolved |
| Q9b | `close_code` (CLOSE) | `sys_choice` | `name=incident^element=close_code^inactive=false` | exact `value` of Solved (Permanently) |
| Q10 | `business_service` | `cmdb_ci_service` | `name=QA Platforms` | `sys_id`, plus its `assignment_group` and `company` |
| Q11 | `service_offering` | `service_offering` | `parent.name=QA Platforms` | `sys_id` of the offering whose `u_environment` matches |
| Q12 | `assignment_group` | `sys_user_group` | `name=AGS_FR_QAS_Service-Managers^ORname=...` | `sys_id`, `active` true |
| Q13 | `company` | `core_company` | `name=AXA GROUP OPERATIONS` | `sys_id` |
| Q14 | Real service for AGPO | `cmdb_ci_service` | `nameLIKEAGPO` | name and sys_id, for SERVICE_MAP |
| Q15 | Duplicate check | `incident` | `correlation_id=P-260916863` | number, state, active |
| Q16 | PD routing key works | PagerDuty | trigger with `dedup_key` dt-problem-TEST-1 | `"status":"success"` |
| Q17 | PD resolve works | PagerDuty | resolve with same `dedup_key` | `"status":"success"` |

## Example: Q1 (start here)

```bash
curl -s -u "$SNOW_AUTH" -G "$SILVA/api/now/v2/table/incident" --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_fields=number,caller_id,u_on_behalf_of,contact_type,company,u_environment,business_service,service_offering,cmdb_ci,category,subcategory,impact,urgency,assignment_group,state,close_code,correlation_id" --data-urlencode "sysparm_display_value=all" | python3 -m json.tool
```

How to read it: each field looks like `"impact": {"value": "4", "display_value": "4 - Low"}`. Put `value` in the payload.

## Example: Q3 (environment choices)

```bash
curl -s -u "$SNOW_AUTH" -G "$SILVA/api/now/v2/table/sys_choice" --data-urlencode "sysparm_query=name=incident^element=u_environment^inactive=false" --data-urlencode "sysparm_fields=value,label" | python3 -m json.tool
```

If this returns nothing, `u_environment` is a reference field, not a choice. Then Q1's `value` is a sys_id and you query the referenced table instead.

## Where Each Answer Goes

| Answer | Put it in |
|---|---|
| Dynatrace JP sys_id | TEST v7 / OPEN `build-payload`: `CALLER_SYS_ID`, `ON_BEHALF_OF_SYS_ID` |
| PRE environment value | Task 1 `PREPROD_LABEL` or task 3 `ENV_VALUE` |
| contact_type, category, subcategory, impact, urgency values | Task 3 settings |
| Resolved state and close_code values | CLOSE `RESOLVED_STATE`, `CLOSE_CODE` |
| AGPO business service name | Task 2 `SERVICE_MAP` (`AGPOCLOUDWEBNGINX: "<name>"`) |

## Common Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| `curl` without `-G --data-urlencode` | "URL rejected: Malformed input" because of `^` and spaces | Use the one-liners as written |
| Copying `display_value` | Reference or choice field stays blank | Copy `value` |
| 403 on `sys_choice` or `core_company` | No read access for the API user | Use Q1 values from INC30340215 instead |
| PD test without the resolve | A test incident stays open and pages | Always run Q17 after Q16 |

## Data Flow

```
your terminal (curl)
  → SILVA Table API GET  (incident, sys_user, sys_choice, cmdb_ci_service, service_offering, sys_user_group, core_company)
  → value / display_value
  → paste into workflow settings (CALLER_SYS_ID, ENV_VALUE, CLOSE_CODE, SERVICE_MAP)
  → TEST v7 task 4 verdict → PASS
```

## Related Files

| File | What it is |
|---|---|
| `7.sh` | All queries Q1 to Q17 as one-liners (not run) |
| `../6-snow-pagerduty-payload-keys/` | The payload keys these queries fill |
| `../4-v7-test-extraction-validate/` | Test workflow that runs similar checks automatically |
