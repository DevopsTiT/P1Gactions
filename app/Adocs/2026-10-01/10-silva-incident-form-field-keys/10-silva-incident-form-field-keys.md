# SILVA Incident Form Field Keys

## Decision Tree

```
Form label on INC30340215 → which API key?
 ├─ Standard ServiceNow field?    → key is known (caller_id, cmdb_ci, impact, ...)  → "Sure"
 ├─ Label starts custom (u_...)?  → best guess, must confirm                          → "Confirm"
 └─ Confirm how?
      ├─ In the form: right-click the label → "Show - 'field_name'"
      ├─ API: sys_dictionary name=incident → element + column_label  (Q1)
      └─ API: INC30340215 with sysparm_display_value=all → every key + value (Q2)
```

## Short Takeaway

| Question | Answer |
|---|---|
| Where do keys come from | The `incident` table column names, not the labels on screen |
| Fields our payload sends | caller_id, u_on_behalf_of, contact_type, company, u_environment, business_service, service_offering, cmdb_ci, category, subcategory, impact, urgency, assignment_group, short_description, description, correlation_id |
| Label "Summary" | Most likely `description` (the long text box) |
| Read-only fields | Priority is calculated from impact and urgency; do not send it |
| How to be 100% sure | Right-click the label in the form, or run Q1 |

## Summary

Each label on the SILVA form maps to a column of the `incident` table. Standard ServiceNow fields have well-known keys. Fields that exist only in SILVA usually start with `u_`, and their exact names must be confirmed with the right-click menu or the `sys_dictionary` query.

## Left Side Of The Form

| Form label | API key | Sure or confirm | Value in INC30340215 |
|---|---|---|---|
| Number | `number` | Sure | INC30340215 |
| Caller | `caller_id` | Sure | Dynatrace JP |
| On Behalf Of | `u_on_behalf_of` | Sure (seen in API result) | Dynatrace JP |
| Contact type | `contact_type` | Sure | Event (value `event`) |
| Company | `company` | Sure | AXA GROUP OPERATIONS |
| Location | `location` | Sure | empty |
| User Location | `u_user_location` | Confirm | None |
| Department | `u_department` | Confirm | empty |
| Environment | `u_environment` | Sure (seen in API result) | Development |
| Business service | `business_service` | Sure | Third Party Services Monitoring Application |
| Service Offering | `service_offering` | Sure | Third Party Services Monitoring Application |
| SO Display Name | `u_so_display_name` | Confirm (likely read-only, filled from the offering) | Silver - Production |
| Configuration item | `cmdb_ci` | Sure | ts12.hk.intraxa |
| Category | `category` | Sure | Other |
| Subcategory | `subcategory` | Sure | Other |
| Hot Ticket | `u_hot_ticket` | Confirm | unchecked |
| First Contact Resolvable | `u_first_contact_resolvable` | Confirm | empty |
| Regulation Type | `u_regulation_type` | Confirm | None |
| Short description | `short_description` | Sure | [DYNATRACE JAPAN][TS12.hk.intraxa] - EPAS Filter Error ... |
| Summary | `description` | Confirm (label renamed in SILVA) | EPAS Filter Error ... Additional Information ... |

## Right Side Of The Form

| Form label | API key | Sure or confirm | Value in INC30340215 |
|---|---|---|---|
| Reported on | `opened_at` | Confirm (could be `u_reported_on`) | 2026-09-29 13:02:44 |
| Actual Start Date | `u_actual_start_date` | Confirm | empty |
| Opened by | `opened_by` | Sure | system |
| Open Group | `u_open_group` | Confirm | empty |
| Incident State | `incident_state` (and `state`) | Sure | Resolved |
| Incident Substate | `u_incident_substate` | Confirm | None |
| Customer Callback | `u_customer_callback` | Confirm | empty |
| Customer Appointment | `u_customer_appointment` | Confirm | empty |
| Priority | `priority` | Sure (read-only, calculated) | 4 - Low |
| Impact | `impact` | Sure | 4 - Low (value `4`) |
| Urgency | `urgency` | Sure | 4 - Low (value `4`) |
| Owner Group | `u_owner_group` | Confirm | empty |
| Assignment group | `assignment_group` | Sure | InfraSupport_Dist-Windows-HK_L2_ASIA |
| Assigned to | `assigned_to` | Sure | empty |
| Effort | `u_effort` | Confirm | empty |
| Due date | `due_date` | Sure | empty |
| Vendor / Interface | `u_vendor_interface` | Confirm | empty |
| External Ticket Number | `u_external_ticket_number` | Confirm | empty |
| Parent Incident | `parent_incident` | Sure | empty |
| Approved | `u_approved` | Confirm | unchecked |

## What This Screenshot Teaches Us

| Observation | What it means |
|---|---|
| Impact 4, Urgency 4, Priority 4 - Low | Our payload values `"4"` and `"4"` are valid. Priority is filled automatically. |
| Contact type shows "Event" | The stored value is `event`, which our payload sends. |
| Business service and Service Offering show the same name | In SILVA an offering can share the name of its service. Run Q3 to see if the two sys_ids differ. If they are the same sys_id in this good incident, then same-sys_id in our payload is acceptable and bug 2 from the last answer is not a bug. |
| Correction | INC30340215 is an EPAS Filter Error on ts12.hk.intraxa (Windows), not the AGPO nginx problem. It is still a different app from the Oracle problem, so company, group and service differences remain expected. |

## Queries

Q1 every incident field key with its label (exact answer for all "Confirm" rows):

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/sys_dictionary" --data-urlencode "sysparm_query=name=incident^ORname=task^elementISNOTEMPTY" --data-urlencode "sysparm_fields=name,element,column_label,internal_type,reference,read_only" --data-urlencode "sysparm_limit=500"
```

Q2 INC30340215 with every key, value and label:

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/incident" --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_display_value=all"
```

Q3 compare the business service and offering sys_ids in INC30340215:

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/incident" --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_display_value=all" --data-urlencode "sysparm_fields=business_service,service_offering,u_so_display_name,description,opened_at"
```

Note: `incident` extends `task`, so many fields (assigned_to, short_description, description, priority) live on `task`. That is why Q1 queries both names.

## Data Flow

```
Form label (screen) → sys_dictionary (element = API key) → payload key → POST /api/now/table/incident
```

## Related Files

| File | What it is |
|---|---|
| `../6-snow-pagerduty-payload-keys/` | The 16 create keys and resolve keys |
| `../9-verify-validate-extraction-result/` | Last verification (bug 2 depends on Q3 here) |
| `10.sh` | Q1 to Q3 |
