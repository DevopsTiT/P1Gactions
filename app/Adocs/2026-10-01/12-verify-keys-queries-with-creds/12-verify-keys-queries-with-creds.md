# Verify Keys Queries With Credentials

## Decision Tree

```
Run V1 (label → key)
 ├─ rows returned?          → copy element per label. Done.
 ├─ [] or 403?              → run V3 (incident read) → keys missing = wrong guess
 │                              └─ find real name → V4 LIKE search
 ├─ need valid values?      → V5 sys_choice
 └─ service == offering?    → V6 compare sys_ids in INC30340215
```

## Short Takeaway

| Question | Answer |
|---|---|
| Credentials | User `Tech_DynatraceJP_WS`, password from your screenshot, filled into every query |
| Endpoint style | `/api/now/v2/table/...` with `Accept: application/json`, same as your file |
| Output | Piped into `jq` so you see only the useful columns |
| Where | `12.sh` in this folder (copy-paste ready) |
| Warning | This folder now holds the password. Do not push P1Gactions. |

## Summary

These are the same verify queries as seq 11, now with the real username and password and the v2 endpoint, so you can paste them straight into the terminal. Start with V1; if it is blocked, V3 works with normal incident read access.

## Queries

All commands below are also in [`12.sh`](12.sh).

V1 label to key:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/sys_documentation" -H 'Accept: application/json' --data-urlencode "sysparm_query=nameINincident,task^language=en^labelINSummary,Reported on,User Location,Department,SO Display Name,Hot Ticket,First Contact Resolvable,Regulation Type,Actual Start Date,Open Group,Incident Substate,Customer Callback,Customer Appointment,Owner Group,Effort,Vendor / Interface,External Ticket Number,Approved,On Behalf Of,Environment" --data-urlencode "sysparm_fields=name,element,label" --data-urlencode "sysparm_limit=200" | jq '.result[] | {label, element, name}'
```

V2 do the guessed keys exist:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/sys_dictionary" -H 'Accept: application/json' --data-urlencode "sysparm_query=nameINincident,task^elementINdescription,opened_at,u_user_location,u_department,u_so_display_name,u_hot_ticket,u_first_contact_resolvable,u_regulation_type,u_actual_start_date,u_open_group,u_incident_substate,u_customer_callback,u_customer_appointment,u_owner_group,u_effort,u_vendor_interface,u_external_ticket_number,u_approved,u_on_behalf_of,u_environment" --data-urlencode "sysparm_fields=name,element,column_label,internal_type,reference,read_only,mandatory" --data-urlencode "sysparm_limit=200" | jq '.result[] | {element, column_label, internal_type, reference, read_only, mandatory}'
```

V3 ask the incident (fallback):

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_display_value=all" --data-urlencode "sysparm_fields=number,caller_id,u_on_behalf_of,contact_type,company,location,u_user_location,u_department,u_environment,business_service,service_offering,u_so_display_name,cmdb_ci,category,subcategory,u_hot_ticket,u_first_contact_resolvable,u_regulation_type,short_description,description,opened_at,u_reported_on,u_actual_start_date,opened_by,u_open_group,incident_state,state,u_incident_substate,u_customer_callback,u_customer_appointment,priority,impact,urgency,u_owner_group,assignment_group,assigned_to,u_effort,due_date,u_vendor_interface,u_external_ticket_number,parent_incident,u_approved,correlation_id" | jq '.result[0]'
```

V3b every real key on the incident:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=number=INC30340215" | jq -r '.result[0] | keys[]'
```

V4 one key, then search by label word:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/sys_dictionary" -H 'Accept: application/json' --data-urlencode "sysparm_query=nameINincident,task^element=u_hot_ticket" --data-urlencode "sysparm_fields=name,element,column_label,internal_type" | jq '.result'
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/sys_dictionary" -H 'Accept: application/json' --data-urlencode "sysparm_query=nameINincident,task^column_labelLIKEHot" --data-urlencode "sysparm_fields=name,element,column_label,internal_type" | jq '.result'
```

V5 valid choice values:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/sys_choice" -H 'Accept: application/json' --data-urlencode "sysparm_query=nameINincident,task^elementINimpact,urgency,u_environment,contact_type,category,subcategory,incident_state,u_incident_substate,u_regulation_type^inactive=false" --data-urlencode "sysparm_fields=element,value,label,dependent_value" --data-urlencode "sysparm_limit=500" | jq '.result[] | {element, value, label, dependent_value}'
```

V6 business service vs offering sys_id in the good incident:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_fields=business_service,service_offering,u_so_display_name" | jq '.result[0]'
```

## Reading Results

| You see | What it means | Next step |
|---|---|---|
| Rows with `element` | Key confirmed | Use it in the payload |
| `[]` | Wrong key or no read access | V4 LIKE search, then V3 |
| `jq: error ... null` | API returned an error, not `result` | Remove the `| jq ...` part to see the raw error |
| `User Not Authenticated` | Password mistyped | Copy from `12.sh`; keep the single quotes |
| V6 two different sys_ids | Service and offering are separate | Keep the workflow bug 2 fix |
| V6 same sys_id | SILVA allows one record for both | Revert the bug 2 fix |

## Data Flow

```
12.sh ──curl -u user:password──► silvastg /api/now/v2/table/<table> ──JSON──► jq ──► only the useful columns
```

## Related Files

| File | What it is |
|---|---|
| `12.sh` | All queries with credentials |
| `../11-queries-verify-incident-keys/` | Same queries with `<password>` placeholder and explanations |
| `../10-silva-incident-form-field-keys/` | Label to key table |
