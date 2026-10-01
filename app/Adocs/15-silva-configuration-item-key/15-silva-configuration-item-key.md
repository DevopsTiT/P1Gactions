# SILVA Configuration Item Key

## Decision Tree

```
Form "Configuration item" (ts12.hk.intraxa) → which key?
 ├─ sys_documentation label "Configuration item"  → u_configuration_item (incident and task)     ✔
 ├─ INC30340215 field holding "ts12"              → u_configuration_item = 1dfdcf8adb8dfa40251af9971d961941 ✔
 ├─ cfbf255f... class                             → "Service Offering" → cmdb_ci really holds the offering ✔
 └─ offerings under the business service          → 1 row, Production, Non-Operational, no u_environment field
```

## Short Takeaway

| Question | Answer |
|---|---|
| Configuration item key | `u_configuration_item` (reference to cmdb_ci) |
| Value in INC30340215 | ts12.hk.intraxa, sys_id `1dfdcf8adb8dfa40251af9971d961941` |
| Offering class confirmed | `cfbf255f1b03b49416deb166464bcb4b` is class "Service Offering" |
| Offering environment | There is no `u_environment` on service_offering; the environment is inside the name |
| Other cmdb_ci references on incident | `u_application` (Application), `u_business_process` (Business Process) |
| Workflow | `HOST_CI_FIELD = "u_configuration_item"`, new host CI check, offering environment checked by name |
| First jq error | `[200~` was pasted in front of `curl` (terminal paste artifact), not a query problem |

## Summary

All three form fields are now mapped. Business service is `u_business_service`, Service Offering is `cmdb_ci`, and Configuration item is `u_configuration_item`. The TEST workflow sends all three and validates each one against SILVA.

## Final Key Map For The Payload

| Form label | Payload key | Points to | Filled from |
|---|---|---|---|
| Business service | `u_business_service` | cmdb_ci_service | servicenow_enrichment sys_id |
| Service Offering | `cmdb_ci` | service_offering | Offering of that service for the environment |
| Configuration item | `u_configuration_item` | cmdb_ci (host, server, DB) | Host CI found by host name or FQDN |
| (retired) | `business_service` | not used | Never send |
| (retired) | `service_offering` | not used | Never send |

## What The Results Showed

| Query | Result |
|---|---|
| sys_documentation label Configuration | incident and task: `u_configuration_item` |
| sys_dictionary reference cmdb_ci | `cmdb_ci` (Service Offering), `u_application` (Application), `u_configuration_item` (Configuration item), `u_business_process` (Business Process) |
| incident field with ts12 | `u_configuration_item` = ts12.hk.intraxa (1dfdcf8adb8dfa40251af9971d961941) |
| cmdb_ci cfbf255f... | class Service Offering, name "... - AXA XL - Production - Silver_24-08-2023 17:00:33" |
| service_offering parent=37273dbc... | 1 offering (cfbf255f...), Non-Operational, no u_environment field returned |

## Two Things Worth Noticing

| Observation | What it means |
|---|---|
| Reference incident environment is Development, but its offering is Production | Real incidents do not always match environment and offering. Our workflow prefers a matching offering and falls back to the first one. |
| The only offering is Non-Operational | SILVA still accepted it. Worth asking the CMDB team if a new offering should be used. |

## Workflow Changes

| Task | Change |
|---|---|
| build-payload | `HOST_CI_FIELD = "u_configuration_item"`, so the host CI sys_id is sent |
| validate-extraction | New check: `u_configuration_item` exists in cmdb_ci |
| validate-extraction | Offering environment rule now checks the offering name (no u_environment on offerings) |
| validate-extraction | Shows offering operational status and all offering names under the service |
| validate-extraction | Reference compare includes `u_configuration_item` |

## Data Flow

```
Davis problem
  → resolve-snow-values: service (not offering) → offering for env (name match) → host CI
  → build-payload
       u_business_service   = 37273dbc... style service sys_id
       cmdb_ci              = cfbf255f... style offering sys_id
       u_configuration_item = 1dfdcf8a... style host sys_id
  → validate-extraction: each sys_id exists in its table, offering parent = service
```

## Commands

Re-check the reference incident with the three final keys (also in [`15.sh`](15.sh)):

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_fields=u_business_service,cmdb_ci,u_configuration_item,u_application,u_business_process" --data-urlencode "sysparm_display_value=all" | jq '.result[0]'
```

## Related Files

| File | What it is |
|---|---|
| `../4-v7-test-extraction-validate/4-v7-test-extraction-validate.workflow.yaml` | Updated TEST workflow |
| `../14-silva-real-service-keys-found/` | Business service and offering keys |
| `15.sh` | Commands |
