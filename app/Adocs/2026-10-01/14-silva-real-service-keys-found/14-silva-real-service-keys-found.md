# SILVA Real Service Keys Found

## Decision Tree

```
Why business_service and service_offering were ""
 │
 ├─ sys_dictionary: business_service  label "ZZZ-Do-not-use-Business service"   → retired field, always empty
 ├─ sys_dictionary: service_offering  label "ZZZ-Do-not-use-Service offering"   → retired field, always empty
 │
 ├─ Form "Business service"  → u_business_service (task, reference cmdb_ci_service)  → 37273dbc...cbf8
 ├─ Form "Service Offering"  → cmdb_ci            (task, reference cmdb_ci)          → cfbf255f...cb4b
 ├─ Form "Configuration item" (ts12.hk.intraxa) → key still unknown → run Q1 to Q3 in 14.sh
 └─ Production (silva.service-now.com) → "User is not authenticated" → account exists only on stg
```

## Short Takeaway

| Question | Answer |
|---|---|
| Why the values were empty | `business_service` and `service_offering` are retired in SILVA (labels start with "ZZZ-Do-not-use") |
| Real key for Business service | `u_business_service` |
| Real key for Service Offering | `cmdb_ci` (SILVA relabelled the standard CI field) |
| Business service and offering same record? | No. Service is 37273dbc1b0f7c50114e0826464bcbf8, offering is cfbf255f1b03b49416deb166464bcb4b. The search fix from seq 9 stays. |
| What was wrong in our payload | We sent `business_service` and `service_offering` (ignored) and put the host in `cmdb_ci` (wrong, that slot is the offering) |
| Workflow | TEST v7 updated. OPEN v7 gets the same keys when it is built. |

## Summary

SILVA moved the business service to a custom field `u_business_service` and reuses the standard `cmdb_ci` field for the service offering. The old standard fields are retired, which is why the API returned empty strings. Our payload now sends the business service sys_id in `u_business_service` and the offering sys_id in `cmdb_ci`. The host CI ("Configuration item" on the form) uses a key we still need to find.

## What The Queries Showed

| Key | Label in sys_dictionary | Table | Points to | Value in INC30340215 |
|---|---|---|---|---|
| `u_business_service` | Business service | task | cmdb_ci_service | Third Party Services Monitoring Application_02-11-2022 11:25:12 (37273dbc1b0f7c50114e0826464bcbf8) |
| `u_lookup_b_service` | Lookup B Service | incident | cmdb_ci_service | Same as u_business_service (probably filled by SILVA) |
| `cmdb_ci` | Service Offering | task | cmdb_ci | Third Party Services Monitoring Application_02-11-2022 11:25:12 - AXA XL - Production - Silver_24-08-2023 17:00:33 (cfbf255f1b03b49416deb166464bcb4b) |
| `business_service` | ZZZ-Do-not-use-Business service | task | cmdb_ci_service | empty |
| `service_offering` | ZZZ-Do-not-use-Service offering | task | service_offering | empty |
| `u_so_dis_name` | (SO Display Name) | incident | text | empty |
| `u_service_request` | Service request | incident | sc_req_item | empty |
| `u_service_recovery_confirmation` | Service Restoration Confirmed | incident | date time | empty |

Other facts from the same run:

| Fact | Value |
|---|---|
| assignment_group | InfraSupport_Dist-WindowsHK_L2_ASIA (633d558e0f3b460094a9716ce1050e5d) |
| u_environment | Development (value is the text `Development`) |
| Prod API | `User is not authenticated` — the account is for silvastg only |

## Payload Change

| Before (wrong) | After (correct) | Value |
|---|---|---|
| `business_service` | `u_business_service` | Business service sys_id from servicenow_enrichment |
| `service_offering` | `cmdb_ci` | Service offering sys_id (offering of that service for the environment) |
| `cmdb_ci` = host | `HOST_CI_FIELD` setting | Host CI sys_id, sent only after you fill the key name |

Changes in `4-v7-test-extraction-validate.workflow.yaml`:

| Task | Change |
|---|---|
| build-payload | Sends `u_business_service` and `cmdb_ci` (offering). New setting `HOST_CI_FIELD = ""`. |
| validate-extraction | Checks `u_business_service` is a real service (not an offering) and `cmdb_ci` is a service_offering whose parent is that service. Reference compare uses the new keys. |

## Still Open: Configuration Item Key

The form shows "Configuration item = ts12.hk.intraxa", but that is not `cmdb_ci`. Run these to find its key, then put it in `HOST_CI_FIELD`.

Q1 label search:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/sys_documentation" -H 'Accept: application/json' --data-urlencode "sysparm_query=nameINincident,task^language=en^labelLIKEConfiguration" --data-urlencode "sysparm_fields=name,element,label" | jq '.result'
```

Q2 dictionary search (also lists every field that points to cmdb_ci):

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/sys_dictionary" -H 'Accept: application/json' --data-urlencode "sysparm_query=nameINincident,task^column_labelLIKEConfiguration^ORcolumn_labelLIKEitem^ORreference=cmdb_ci" --data-urlencode "sysparm_fields=name,element,column_label,reference" | jq '.result'
```

Q3 which key holds "ts12" in this incident:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_display_value=true" | jq '.result[0] | with_entries(select((.value | tostring) | test("ts12"; "i")))'
```

Q4 confirm the offering class:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci" -H 'Accept: application/json' --data-urlencode "sysparm_query=sys_id=cfbf255f1b03b49416deb166464bcb4b" --data-urlencode "sysparm_fields=sys_id,name,sys_class_name" --data-urlencode "sysparm_display_value=true" | jq '.result[0]'
```

Q5 offerings under that business service (shows the per-environment pattern):

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/service_offering" -H 'Accept: application/json' --data-urlencode "sysparm_query=parent=37273dbc1b0f7c50114e0826464bcbf8" --data-urlencode "sysparm_fields=sys_id,name,u_environment,operational_status" --data-urlencode "sysparm_display_value=true" | jq '.result'
```

## Data Flow

```
Davis problem
  → resolve-snow-values: business service (cmdb_ci_service, not offering) + offering for the environment
  → build-payload
       u_business_service = service sys_id      (form "Business service")
       cmdb_ci            = offering sys_id     (form "Service Offering")
       HOST_CI_FIELD      = host CI sys_id      (form "Configuration item", key TBD)
  → validate-extraction: service is a service, offering parent = service
```

## Related Files

| File | What it is |
|---|---|
| `../4-v7-test-extraction-validate/4-v7-test-extraction-validate.workflow.yaml` | Updated TEST workflow |
| `../13-why-service-fields-empty/` | Queries that found this |
| `14.sh` | Q1 to Q5 plus copy commands |
