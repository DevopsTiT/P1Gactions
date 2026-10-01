# Queries To Verify Incident Keys

## Decision Tree

```
Want to know if a key like u_hot_ticket is real?
 │
 ├─ V1 label → key  (sys_documentation)     best: you know the label, it returns the key
 ├─ V2 key exists?  (sys_dictionary)        returns a row for each real key, nothing for a wrong one
 ├─ V3 ask the incident for the keys        wrong keys are simply missing from the answer
 ├─ V4 one key at a time                    quick yes/no for a single guess
 ├─ V5 choice values (sys_choice)           valid values for choice fields
 │
 └─ HTTP 403 or empty result on V1/V2?      account cannot read system tables
        → use V3 (incident read works)  or  browser URLs B1/B2  or  right-click label
```

## Short Takeaway

| Question | Answer |
|---|---|
| Best query | V1: search `sys_documentation` by the label you see on the form; it returns the key |
| Prove a guessed key exists | V2: search `sys_dictionary` by key; no row means the key is wrong |
| If system tables are blocked | V3: ask INC30340215 for the guessed keys; only real keys come back |
| Valid values | V5: `sys_choice` for impact, urgency, u_environment and others |
| No API access at all | Open B1 or B2 in the browser, or right-click the label on the form |

## Summary

ServiceNow keeps labels in `sys_documentation` and field definitions in `sys_dictionary`. Query the label to get the key, or query the key to prove it exists. If your account cannot read those tables, ask the incident itself for the keys: SILVA silently drops any key that does not exist.

## V1 Label To Key

You know the label on the form. This returns the key for each label.

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/sys_documentation" --data-urlencode "sysparm_query=nameINincident,task^language=en^labelINSummary,Reported on,User Location,Department,SO Display Name,Hot Ticket,First Contact Resolvable,Regulation Type,Actual Start Date,Open Group,Incident Substate,Customer Callback,Customer Appointment,Owner Group,Effort,Vendor / Interface,External Ticket Number,Approved,On Behalf Of,Environment" --data-urlencode "sysparm_fields=name,element,label" --data-urlencode "sysparm_limit=200"
```

| Result column | What it means |
|---|---|
| `label` | Text on the form |
| `element` | The API key to use in the payload |
| `name` | Table where the field lives (`incident` or `task`) |

## V2 Does The Key Exist

You have a guessed key. Each real key returns one row; a wrong key returns nothing.

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/sys_dictionary" --data-urlencode "sysparm_query=nameINincident,task^elementINdescription,opened_at,u_user_location,u_department,u_so_display_name,u_hot_ticket,u_first_contact_resolvable,u_regulation_type,u_actual_start_date,u_open_group,u_incident_substate,u_customer_callback,u_customer_appointment,u_owner_group,u_effort,u_vendor_interface,u_external_ticket_number,u_approved,u_on_behalf_of,u_environment" --data-urlencode "sysparm_fields=name,element,column_label,internal_type,reference,read_only,mandatory" --data-urlencode "sysparm_limit=200"
```

| Result column | What it means | Why you care |
|---|---|---|
| `element` | The real key | Use this in the payload |
| `column_label` | Label on the form | Confirms you have the right field |
| `internal_type` | reference, choice, string, boolean, glide_date_time | Tells you what kind of value to send |
| `reference` | Table a reference field points to | You must send a sys_id from this table |
| `read_only` | true means users cannot edit it | Do not send it |
| `mandatory` | true means required | Must be in the payload |

## V3 Ask The Incident (works with normal read access)

Ask INC30340215 for all keys, sure and guessed. Keys that do not exist are not returned.

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/incident" --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_display_value=all" --data-urlencode "sysparm_fields=number,caller_id,u_on_behalf_of,contact_type,company,location,u_user_location,u_department,u_environment,business_service,service_offering,u_so_display_name,cmdb_ci,category,subcategory,u_hot_ticket,u_first_contact_resolvable,u_regulation_type,short_description,description,opened_at,u_reported_on,u_actual_start_date,opened_by,u_open_group,incident_state,state,u_incident_substate,u_customer_callback,u_customer_appointment,priority,impact,urgency,u_owner_group,assignment_group,assigned_to,u_effort,due_date,u_vendor_interface,u_external_ticket_number,parent_incident,u_approved,correlation_id"
```

Optional, if `jq` is installed, list only the keys that came back:

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/incident" --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_display_value=all" | jq -r '.result[0] | keys[]'
```

The second command returns every key of the incident. Look for names that match the labels (for example anything with `hot`, `regulation`, `substate`).

## V4 One Key At A Time

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/sys_dictionary" --data-urlencode "sysparm_query=nameINincident,task^element=u_hot_ticket" --data-urlencode "sysparm_fields=name,element,column_label,internal_type"
```

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/sys_dictionary" --data-urlencode "sysparm_query=nameINincident,task^column_labelLIKEHot" --data-urlencode "sysparm_fields=name,element,column_label,internal_type"
```

| Result | What it means |
|---|---|
| `{"result":[{...}]}` | Key exists |
| `{"result":[]}` | Key is wrong; use the LIKE version to find the real one |

## V5 Valid Values For Choice Fields

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/sys_choice" --data-urlencode "sysparm_query=nameINincident,task^elementINimpact,urgency,u_environment,contact_type,category,subcategory,incident_state,u_incident_substate,u_regulation_type^inactive=false" --data-urlencode "sysparm_fields=element,value,label,dependent_value" --data-urlencode "sysparm_limit=500"
```

| Result column | What it means |
|---|---|
| `value` | What you send in the payload (for example `4`) |
| `label` | What the form shows (for example `4 - Low`) |
| `dependent_value` | Subcategory list depends on this category |

## Browser Alternative (no API access needed)

B1 dictionary list for incident and task:

```
https://silvastg.service-now.com/sys_dictionary_list.do?sysparm_query=nameINincident,task^elementSTARTSWITHu_
```

B2 every field with label, as a list you can export:

```
https://silvastg.service-now.com/sys_documentation_list.do?sysparm_query=nameINincident,task^language=en
```

B3 on the incident form: right-click a label, then pick **Show - 'field_name'**.

## Common Results

| You see | What it means | Next step |
|---|---|---|
| HTTP 403 or `User Not Authorized` | Account cannot read system tables | Use V3 or the browser |
| `{"result":[]}` on V1 or V2 | Label or key does not match, or no read access | Try V4 LIKE search, then V3 |
| Key missing in V3 output | That key does not exist on incident | Fix the guess |
| Key present with empty value | Key is real, just not filled in this incident | Keep it |

## Data Flow

```
form label ──V1──► sys_documentation ──► element (key)
guessed key ──V2/V4──► sys_dictionary ──► exists? type? reference? read_only?
guessed keys ──V3──► incident INC30340215 ──► only real keys returned
choice key ──V5──► sys_choice ──► valid value + label
```

## Related Files

| File | What it is |
|---|---|
| `../10-silva-incident-form-field-keys/` | Label to key table (sure and confirm) |
| `../6-snow-pagerduty-payload-keys/` | Payload keys we send |
| `11.sh` | All queries as one-liners |
