# SILVA Export Groups And Business Services

```
Need all SILVA assignment groups + business services
 Quick, by hand?
   → SILVA UI: type <table>.list in the filter navigator → add columns → right-click header → Export → CSV
 Repeatable / scripted?
   → Table API (GET, read-only) with Tech_DynatraceJP_WS → jq → CSV
 Which tables?
   assignment groups   → sys_user_group
   business services   → cmdb_ci_service
   service offerings   → service_offering (parent = business service)
   host → service link → svc_ci_assoc (service mapping) or cmdb_rel_ci (CI relationships)
   host's own group    → cmdb_ci_server (support_group / assignment_group)
 Empty result or 403?
   → API user lacks read on that table → use your own UI login, or ask the SILVA admin
 Too many rows?
   → count first (stats API) → page with sysparm_limit + sysparm_offset
```

## Short takeaway

| Question | Answer |
|---|---|
| Fastest way | Open the list in the SILVA UI and export to CSV. |
| Scripted way | Table API GET requests. Read-only, so they change nothing. |
| Assignment groups table | `sys_user_group` |
| Business services table | `cmdb_ci_service` |
| Service offerings table | `service_offering` |
| Which service a host belongs to | `svc_ci_assoc` or `cmdb_rel_ci` |
| Common blocker | The API user may not have read access. Your own login in the UI usually does. |

## Summary

Everything we need already lives in SILVA tables. Export the three lists (groups, services, offerings) and the host-to-service links once. That gives the mapping Abhay asked for, and the default service and group to use when nothing matches.

## Option 1: Export from the SILVA UI (recommended first)

| Step | What to do |
|---|---|
| 1 | Log in to https://silvastg.service-now.com with your own account. |
| 2 | In the filter navigator (top left), type `sys_user_group.list` and press Enter. |
| 3 | Filter if useful, for example Active = true, or Name contains AXAJP. |
| 4 | Right-click a column header, choose Configure then List Layout, and add the columns you want. |
| 5 | Right-click a column header, choose Export, then CSV (or Excel). |
| 6 | Repeat for `cmdb_ci_service.list`, `service_offering.list` and `svc_ci_assoc.list`. |

You can also export straight from a URL. Open this in the browser while logged in:

```
https://silvastg.service-now.com/sys_user_group_list.do?CSV&sysparm_query=active=true
```

| URL export | What you get |
|---|---|
| `sys_user_group_list.do?CSV&sysparm_query=active=true` | All active assignment groups |
| `cmdb_ci_service_list.do?CSV` | All business services |
| `service_offering_list.do?CSV` | All service offerings |
| `svc_ci_assoc_list.do?CSV` | Service to CI links |

Exports are usually capped (often 10,000 rows). Filter or split if you hit the cap.

## Option 2: Table API (scripted)

All commands are in `18.sh`. Replace `__SNOW_PASSWORD__` first. `jq` turns the JSON into CSV.

| What | Table | Useful fields |
|---|---|---|
| Assignment groups | `sys_user_group` | name, sys_id, active, type, manager, email, parent, description |
| Business services | `cmdb_ci_service` | name, sys_id, operational_status, support_group, assignment_group, managed_by_group, owned_by, busines_criticality |
| Service offerings | `service_offering` | name, sys_id, parent (the business service), u_environment, support_group, assignment_group, company |
| Service to CI links (service mapping) | `svc_ci_assoc` | service_id, ci_id |
| General CI relationships | `cmdb_rel_ci` | parent, child, type |
| Host details | `cmdb_ci_server` | name, sys_id, support_group, assignment_group |

Field names differ between instances. If a column comes back empty, open one record in the UI and check the real field name (right-click the label, then Show).

Count first so you know how many pages you need:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/stats/sys_user_group?sysparm_count=true&sysparm_query=active=true"
```

Export active assignment groups to CSV:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/sys_user_group?sysparm_query=active=true%5EORDERBYname&sysparm_fields=name,sys_id,type,manager,email,parent&sysparm_display_value=true&sysparm_exclude_reference_link=true&sysparm_limit=10000" | jq -r '.result[] | [.name,.sys_id,.type,.manager,.email,.parent] | @csv' > silva_assignment_groups.csv
```

Export business services with their groups:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci_service?sysparm_query=ORDERBYname&sysparm_fields=name,sys_id,operational_status,support_group,assignment_group,managed_by_group,owned_by&sysparm_display_value=true&sysparm_exclude_reference_link=true&sysparm_limit=10000" | jq -r '.result[] | [.name,.sys_id,.operational_status,.support_group,.assignment_group,.managed_by_group,.owned_by] | @csv' > silva_business_services.csv
```

Export offerings with their parent service and environment:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/service_offering?sysparm_query=ORDERBYname&sysparm_fields=name,sys_id,parent,u_environment,support_group,assignment_group,company&sysparm_display_value=true&sysparm_exclude_reference_link=true&sysparm_limit=10000" | jq -r '.result[] | [.name,.sys_id,.parent,.u_environment,.support_group,.assignment_group,.company] | @csv' > silva_service_offerings.csv
```

Find which business service a host belongs to (replace the host name):

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/svc_ci_assoc?sysparm_query=ci_id.name=__HOST_NAME__&sysparm_fields=service_id,ci_id&sysparm_display_value=true&sysparm_exclude_reference_link=true"
```

The same through general CI relationships:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_rel_ci?sysparm_query=child.name=__HOST_NAME__%5Eparent.sys_class_name=cmdb_ci_service&sysparm_fields=parent,child,type&sysparm_display_value=true&sysparm_exclude_reference_link=true"
```

A host's own support and assignment group:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci_server?sysparm_query=name=__HOST_NAME__&sysparm_fields=name,sys_id,support_group,assignment_group&sysparm_display_value=true&sysparm_exclude_reference_link=true"
```

Page through big tables by raising the offset in steps of the limit:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci_service?sysparm_query=ORDERBYname&sysparm_fields=name,sys_id&sysparm_limit=5000&sysparm_offset=5000"
```

## If you get nothing back

| What you see | Likely cause | What to do |
|---|---|---|
| HTTP 401 | Wrong password | Check the password. |
| HTTP 403 | The API user has no read access on the table | Use your own login in the UI, or ask the SILVA admin for read access. |
| `"result": []` but the UI shows rows | Row-level access rules hide records from the API user | Same as 403: use the UI or ask for access. |
| A column is empty for every row | The field has a different name on SILVA | Check the real field name on one record in the UI. |
| `jq: command not found` | jq is not installed | Run `brew install jq`, or drop the jq part and save the raw JSON. |

## How this feeds the workflow

| Export | Used for |
|---|---|
| Business services | Checking the names we tag in Dynatrace exist, and choosing the default business service. |
| Offerings | Picking the offering per environment for each service. |
| Assignment groups | Choosing the L1 and L2 group names, and the default group. |
| Service to CI links | Checking that Dynatrace host names exist in SILVA, so SILVA can fill the service itself. |

## Data flow map

```
SILVA tables                    export                 use
─────────────                   ──────                 ───
sys_user_group      ──► silva_assignment_groups.csv ──► L1 / L2 / default group
cmdb_ci_service     ──► silva_business_services.csv ──► tag values + default service
service_offering    ──► silva_service_offerings.csv ──► offering per environment
svc_ci_assoc /
cmdb_rel_ci         ──► host → service lookups      ──► does SILVA know our hosts?
        │
        ▼
Dynatrace tags (silva_business_service, silva_group_l1, silva_group_l2) + workflow defaults
```

## Related files

| File | Purpose |
|---|---|
| `18.sh` | All export and lookup commands |
| `../17-silva-payload-service-mapping-explain/` | Why these values are needed |
| `../16-open-close-service-sysid-low-priority/` | Current YAMLs |

Commands: see `18.sh` in this folder.
