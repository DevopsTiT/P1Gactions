# SNOW Payload Matching The Incident Form

## Decision tree

```
Build SNOW incident body
 │
 ├─ fixed values (from INC30340215)
 │    ├─ caller_id = Dynatrace JP
 │    ├─ u_on_behalf_of = Dynatrace JP
 │    ├─ contact_type = event
 │    ├─ category = other
 │    ├─ subcategory = other
 │    ├─ impact = 4
 │    └─ urgency = 4
 │
 ├─ looked up in SILVA
 │    ├─ assignment_group ← group tag (Database_AXAJP)
 │    ├─ business_service ← CI link → search → DEFAULT_BUSINESS_SERVICE
 │    ├─ service_offering ← offering of the service → DEFAULT_SERVICE_OFFERING
 │    ├─ cmdb_ci ← host or DB CI
 │    └─ company ← business service company → AXA GROUP OPERATIONS
 │
 ├─ from the event
 │    ├─ u_environment ← environment tag label
 │    ├─ short_description ← [DYNATRACE JAPAN][CI or host] - event name
 │    ├─ description ← event text + Additional Information JSON
 │    └─ correlation_id ← display_id
 │
 └─ snow_form_check
      ├─ any mandatory field empty? → MISSING, ready_for_snow false
      └─ all filled → ready_for_snow true
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | The SNOW body now fills every field seen on INC30340215 |
| Which fields are mandatory on the form? | Caller, Environment, Business service, Service Offering, Category, Subcategory, Short description, Summary |
| What if no business service is found? | It falls back to "Third Party Services Monitoring Application", like INC30340215 |
| Are choice fields sent as labels? | No. They are sent as stored values (for example impact "4"). Confirm them with the GET in `6.sh`. |
| How do I see gaps? | Read `snow_form_check` in the output. One row per form field. |

## Summary

The incident form needs more than the group and service. v4 now also sends caller, on behalf of, company, category, subcategory and the environment, and it formats the Summary like INC30340215. A new `snow_form_check` block lists each form field with its value and whether it is filled.

## Form field to payload mapping

| Form label | Payload field | Where the value comes from | INC30340215 value |
|---|---|---|---|
| Caller | `caller_id` | Setting `CALLER` | Dynatrace JP |
| On Behalf Of | `u_on_behalf_of` | Setting `ON_BEHALF_OF` | Dynatrace JP |
| Contact type | `contact_type` | Setting `CONTACT_TYPE` | Event |
| Company | `company` | Business service company, else `DEFAULT_COMPANY` | AXA GROUP OPERATIONS |
| Environment | `u_environment` | Environment tag label, else offering environment | Development |
| Business service | `business_service` | CI link, search, else `DEFAULT_BUSINESS_SERVICE` | Third Party Services Monitoring Application |
| Service Offering | `service_offering` | Service offering for the environment, else `DEFAULT_SERVICE_OFFERING` | Third Party Services Monitoring Application |
| Configuration Item | `cmdb_ci` | Host or DB CI in SILVA | ts12.hk.intraxa |
| Category | `category` | Setting `CATEGORY` | Other |
| Subcategory | `subcategory` | Setting `SUBCATEGORY` | Other |
| Impact | `impact` | Setting `IMPACT` | 4 - Low |
| Urgency | `urgency` | Setting `URGENCY` | 4 - Low |
| Assignment group | `assignment_group` | Group tag, checked in SILVA | InfraSupport_Dist-WindowsHK_L2_ASIA |
| Short description | `short_description` | `[DYNATRACE JAPAN][CI or host] - event name` | [DYNATRACE JAPAN][TS12.hk.intraxa] - EPAS Filter Error... |
| Summary | `description` | Event text plus Additional Information JSON | See below |
| (hidden) | `correlation_id` | `display_id` | Used by CLOSE to find the ticket |

Fields not sent on purpose:

| Form label | Why |
|---|---|
| Priority | SNOW calculates it from impact and urgency |
| SO Display Name | Filled by SNOW from the service offering |
| Opened by | SNOW sets it to the API user |
| Regulation Type | Left as None, same as INC30340215 |

## Summary field layout

```
<event description or event name>
Additional Information:
{
  "correlation_id": "<Dynatrace entity id>",
  "discovered_name": "<entity name>",
  "dynatrace_severity": "<event.category>",
  "environmentId": "<Dynatrace tenant id>",
  "environmentName": "AXA AS STG",
  "event_properties": [
    { "key": "dt.davis.analysis_time_budget", "value": "0" },
    { "key": "event.description", "value": "..." },
    { "key": "entity_tags", "value": "AGO_DB:ORACLE, ..." }
  ],
  "problem_displayId": "P-...",
  "u_external_url": "<problem link>"
}
```

## Expected SNOW body for the Oracle event

```json
{
  "caller_id": "Dynatrace JP",
  "u_on_behalf_of": "Dynatrace JP",
  "contact_type": "event",
  "company": "<service company sys_id, or AXA GROUP OPERATIONS>",
  "u_environment": "Integration / Test",
  "business_service": "<found sys_id, or Third Party Services Monitoring Application sys_id>",
  "service_offering": "<offering sys_id>",
  "cmdb_ci": "<deaa310b or DEA10B01 sys_id if found>",
  "category": "other",
  "subcategory": "other",
  "impact": "4",
  "urgency": "4",
  "assignment_group": "5223d8c61b8f3c54688064e4604bcb12",
  "short_description": "[DYNATRACE JAPAN][deaa310b] - Oracle DB Instance down",
  "description": "Oracle DB Instance down\nAdditional Information:\n{...}",
  "correlation_id": "P-260916434"
}
```

## Things to confirm once

| Item | How to confirm |
|---|---|
| Real field name of "On Behalf Of" | GET INC30340215 in `6.sh` and look for the key that holds "Dynatrace JP" |
| Real field name of "Environment" | Same GET. Look for the key with "Development". |
| Stored values of category, subcategory, impact, urgency, contact type | Same GET with `sysparm_display_value=all` shows `value` and `display_value` |
| Dynatrace tenant name | Set `DT_ENVIRONMENT_NAME` |
| Default service is acceptable for Oracle alerts | Ask the SILVA team |

## Data flow

```
event ──► TASK 1
            │ dynatrace_alert, event_properties, dt_environment_id, tags
            ▼
          TASK 2 ── GET ──► SILVA
            │ group, business service (or default), offering (or default),
            │ CI, company
            ▼
          TASK 3
            │ fixed settings + looked-up values + event text
            ▼
          snow_incident_payload + snow_form_check + ready_for_snow
```

## Related files

| File | What it is |
|---|---|
| `../3-extract-v4-business-service-and-group/3-extract-v4-business-service-and-group.workflow.yaml` | Updated workflow |
| `6.sh` | GET of INC30340215 to confirm field names and values |

## Commands

See `6.sh`. The key one:

```bash
curl -s -G -u 'Tech_DynatraceJP_WS:<password>' 'https://silvastg.service-now.com/api/now/v2/table/incident' --data-urlencode 'sysparm_query=number=INC30340215' --data-urlencode 'sysparm_display_value=all' --data-urlencode 'sysparm_exclude_reference_link=true' | jq '.result[0] | with_entries(select(.value.display_value != "" and .value.display_value != null))'
```
