# Export The Whole SILVA Mapping Table

## Decision tree

```
Need the whole table (every host → business service → offering → group → environment)
 │
 ├─ Can you log in to SILVA in a browser?
 │    yes → Method 1: list view → add dot-walked columns → right-click header → Export → CSV
 │           more than ~10,000 rows? → split with a filter (A–M, N–Z) or use Method 2
 │    no  → Method 2
 │
 ├─ Method 2: Table API with dot-walked fields
 │    result [] → does svc_ci_assoc have data? check the count line
 │          empty → use cmdb_rel_ci export instead (30.sh line 6)
 │    HTTP 403  → ask the SILVA admin for read access on the tables listed below
 │    X-Total-Count > 10000 → run the next offset line (10000, 20000 ...)
 │
 └─ Have 3 CSVs (host-service, offerings, groups)?
      → run 30-join-silva-tables.py → silva_whole_table.csv (one row per host + offering)
```

## Short takeaway

| Question | Answer |
|---|---|
| Is there one SILVA table that has everything? | No. The data is spread across `svc_ci_assoc`, `service_offering`, `cmdb_ci_service` and `sys_user_group`. |
| Which table is the backbone? | `svc_ci_assoc`, which has one row per host and business service pair. |
| How do I avoid many exports? | Use dot-walking. For example, `ci_id.name` pulls the host name through the reference, so one export gives you host and service columns together. |
| What still needs a second export? | The offerings, because one business service can have many offerings. |
| How do I get one final table? | Run the join script `30-join-silva-tables.py`. |

## Summary

SILVA (ServiceNow) stores the pieces in separate tables. Export the host-to-service table with extra "dot-walked" columns so it already shows the service's support group, then export the offerings. A small script joins them into one CSV. You can do it all from the browser (easiest) or with the API (repeatable).

## What each column comes from

| Final column | Where it lives | How it gets into the export |
|---|---|---|
| host | `svc_ci_assoc.ci_id` → `cmdb_ci.name` | Dot-walk field `ci_id.name` |
| host_fqdn | `cmdb_ci.fqdn` | Dot-walk field `ci_id.fqdn` |
| host_class | `cmdb_ci.sys_class_name` | Dot-walk field `ci_id.sys_class_name` |
| host_status | `cmdb_ci.install_status` | Dot-walk field `ci_id.install_status` |
| host_support_group | `cmdb_ci.support_group` | Dot-walk field `ci_id.support_group` |
| business_service | `svc_ci_assoc.service_id` | Dot-walk field `service_id.name` |
| service_support_group | `cmdb_ci_service.support_group` | Dot-walk field `service_id.support_group` |
| service_status | `cmdb_ci_service.operational_status` | Dot-walk field `service_id.operational_status` |
| offering | `service_offering.name` | Second export, joined on business service name |
| offering_environment | `service_offering.u_environment` | Second export |
| offering_support_group | `service_offering.support_group` | Second export |

**Dot-walking** means following a reference field to read a field on the linked record. `service_id` points to the business service record, so `service_id.support_group` reads that record's support group.

## Method 1: browser export (easiest)

1. Log in at https://silvastg.service-now.com.
2. Type `svc_ci_assoc.list` into the filter navigator (the search box at the top left) and press Enter.
3. Click the gear icon at the top left of the list to open "Personalize List Columns".
4. Add columns by expanding the reference fields (click the `+` next to "Configuration item" and "Service"):
   - Configuration item → Name, FQDN, Class, Install Status, Support group
   - Service → Name, Support group, Operational status
5. Optional: filter out retired hosts (Configuration item.Install Status is not Retired).
6. Right-click any column header, then choose **Export → CSV**. Save the file as `silva_ci_service.csv`.
7. Repeat for `service_offering.list` with the columns Name, Parent, Environment, Support group and Company. Save the file as `silva_service_offerings.csv`.
8. Repeat for `sys_user_group.list` (filter Active = true) with the columns Name, Manager, Email and Parent. Save the file as `silva_assignment_groups.csv`.

| Situation | What to do |
|---|---|
| The export stops at around 10,000 rows, or SILVA asks you to wait for an email | SILVA has an export row limit. Split the export with a filter (for example, name starts with A–M, then N–Z) or use Method 2. |
| The Export menu is missing | Your role may not allow export. Ask the SILVA admin. |
| The list is empty | This instance may use `cmdb_rel_ci` for service links. Export `cmdb_rel_ci.list` filtered on Parent.Class = Business Service instead. |

## Method 2: API export (repeatable)

The commands are in `30.sh`. Replace `__SNOW_PASSWORD__` before running. I have not run them.

| Line in 30.sh | What it does |
|---|---|
| 1 | Counts rows in `svc_ci_assoc`, so you know how many pages you need |
| 2 | Exports rows 0–9,999 of host → service with dot-walked columns into `silva_ci_service_0.csv` |
| 3 | Exports the next page (offset 10000). Add more lines with a higher offset if the count is larger. |
| 4 | Joins the pages into `silva_ci_service.csv` |
| 5 | Exports all offerings into `silva_service_offerings.csv` |
| 6 | Fallback: exports `cmdb_rel_ci` service links if `svc_ci_assoc` is empty |
| 7 | Exports all active groups into `silva_assignment_groups.csv` |
| 8 | Exports the valid incident Environment labels |
| 9 | Runs the join script to produce `silva_whole_table.csv` |

The main export line:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/svc_ci_assoc?sysparm_query=ORDERBYci_id.name&sysparm_fields=ci_id.name,ci_id.fqdn,ci_id.sys_class_name,ci_id.install_status,ci_id.support_group,service_id.name,service_id.support_group,service_id.operational_status&sysparm_display_value=true&sysparm_exclude_reference_link=true&sysparm_limit=10000&sysparm_offset=0" | jq -r '["host","host_fqdn","host_class","host_status","host_support_group","business_service","service_support_group","service_status"], (.result[] | [.["ci_id.name"],.["ci_id.fqdn"],.["ci_id.sys_class_name"],.["ci_id.install_status"],.["ci_id.support_group"],.["service_id.name"],.["service_id.support_group"],.["service_id.operational_status"]]) | @csv' > silva_ci_service_0.csv
```

| Parameter | What it means |
|---|---|
| `sysparm_fields=ci_id.name,...` | Only these columns are returned, and dot-walked names are allowed |
| `sysparm_display_value=true` | Names are returned instead of sys_ids |
| `sysparm_exclude_reference_link=true` | Removes the extra link objects, so the values are plain strings |
| `sysparm_limit=10000` | Page size. Keep it at 10,000 or less. |
| `sysparm_offset=0` | Where the page starts. The next page uses 10000. |

## Join into one table

`30-join-silva-tables.py` (Python standard library only) reads `silva_ci_service.csv` and `silva_service_offerings.csv`. It writes `silva_whole_table.csv` with one row per host, business service and offering. If a service has no offering, the row is still kept with a blank offering.

Final columns:

| Column | Example |
|---|---|
| host | ts12.hk.intraxa |
| business_service | Third Party Services Monitoring Application |
| service_support_group | InfraSupport_Dist-WindowsHK_L2_ASIA |
| offering | Third Party Services Monitoring Application - ... - Integration / Test - Standard |
| offering_environment | Integration / Test |
| offering_support_group | (value from SILVA) |

You can do the same join in Excel with XLOOKUP on business_service, but one host can have several offerings, and XLOOKUP only returns the first match. The script keeps all of them.

## How to use the table in the workflow

| Column in the table | Where it goes in the OPEN YAML |
|---|---|
| host plus business_service | Checks that SILVA will derive the service from the configuration item. If a host is missing, it needs a `SYSTEM_MAP` row or a CMDB fix. |
| business_service plus offering | The `businessService` and `serviceOffering` values in `SYSTEM_MAP` |
| service_support_group | The `l2Group` value in `SYSTEM_MAP` |
| offering_environment | The `ENVIRONMENT` map and the `SILVA_ENVIRONMENTS` allowlist |

## Data flow map

```
cmdb_ci (host) ──ci_id──► svc_ci_assoc ◄──service_id── cmdb_ci_service (business service)
                               │                              │ support_group ──► sys_user_group
                               │                              │
             export with dot-walked columns        service_offering.parent = business service
                               │                              │
                     silva_ci_service.csv          silva_service_offerings.csv
                               └──────────┬───────────────────┘
                                          ▼
                             30-join-silva-tables.py
                                          ▼
                               silva_whole_table.csv
                                          ▼
                    SYSTEM_MAP / ENVIRONMENT in the OPEN workflow YAML
```

## Tables the API user needs to read

If an API call returns `[]` or 403, ask the SILVA admin to give `Tech_DynatraceJP_WS` read access to these tables:

| Table | Why it is needed |
|---|---|
| `svc_ci_assoc` | Host to business service links |
| `cmdb_rel_ci` | Fallback relationship table |
| `cmdb_ci` | Host names and support groups |
| `cmdb_ci_service` | Business services |
| `service_offering` | Offerings and environments |
| `sys_user_group` | Groups |
| `sys_choice` | Environment labels |

## Related files

| File | Purpose |
|---|---|
| `30.sh` | Export commands (one per line, not run) |
| `30-join-silva-tables.py` | Joins the exports into one table |
| `../18-silva-export-groups-business-services/` | The earlier per-table exports |
| `../29-get-host-info-from-silva/` | Looking up one host |

## Commands

See `30.sh`. The first line shows how many rows exist:

```bash
curl -s -I -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/svc_ci_assoc?sysparm_limit=1" | grep -i x-total-count
```
