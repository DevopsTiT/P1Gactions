# SILVA Common API Reference

## Decision tree

```
What do you need from SILVA?
 │
 ├─ Don't know the table or field name?     → Discovery APIs (sys_db_object, sys_dictionary, sys_choice)   32.sh 1–4
 ├─ Read records (host, service, offering)? → Table API GET with sysparm_query + dot-walked fields       32.sh 5–14
 ├─ Host with all its relationships?        → CMDB Instance API                                           32.sh 15–17
 ├─ How many / grouped counts?              → Aggregate (stats) API with sysparm_group_by                 32.sh 18–21
 ├─ Whole table as a file?                  → Table API with paging, or list URL ?CSV / ?EXCEL            32.sh 22–26
 ├─ Create / update / resolve incident?     → Table API POST / PATCH (what the workflow does)             32.sh 27–30
 └─ Error?
      401 → wrong user or password
      403 → no read ACL on that table → ask the SILVA admin
      []  → the query matched nothing, or ACLs hide the rows → test the same filter in the browser
      400 → bad field name in sysparm_query → check sys_dictionary
```

## Short takeaway

| Question | Answer |
|---|---|
| Which API is used most? | The Table API (`/api/now/v2/table/<table>`). It reads and writes any table. |
| Which API gives counts and group-by? | The Aggregate API (`/api/now/stats/<table>`). |
| Which API gives a host plus its relationships in one call? | The CMDB Instance API (`/api/now/cmdb/instance/<class>/<sys_id>`). |
| How do I find field names? | Query `sys_dictionary` through the Table API. |
| How do I get a CSV without writing code? | Open `<table>_list.do?CSV` in a logged-in browser. |

## Summary

Almost everything goes through the Table API with a filter (`sysparm_query`) and a column list (`sysparm_fields`). Use the Aggregate API for counts per environment or per service, and the CMDB Instance API when you want one host with every relationship. The discovery tables tell you the exact table and field names before you build a query. All commands are in `32.sh`, one per line. I have not run them.

## Base settings used in every call

| Item | Value |
|---|---|
| Instance | `https://silvastg.service-now.com` |
| User | `Tech_DynatraceJP_WS` |
| Password | Replace `__SNOW_PASSWORD__` in `32.sh` |
| Header | `Accept: application/json` (and `Content-Type: application/json` for POST and PATCH) |
| Tool | `curl` plus `jq` for reading JSON (`brew install jq`) |

## 1. The APIs

| API | URL pattern | Methods | What it is for |
|---|---|---|---|
| Table API | `/api/now/v2/table/<table>` | GET, POST | List records or create one |
| Table API (single record) | `/api/now/v2/table/<table>/<sys_id>` | GET, PATCH, PUT, DELETE | Read, update or delete one record |
| Aggregate API | `/api/now/stats/<table>` | GET | Count, group by, min, max, average |
| CMDB Instance API | `/api/now/cmdb/instance/<class>` | GET | List CIs of one class (servers, services) |
| CMDB Instance API (single CI) | `/api/now/cmdb/instance/<class>/<sys_id>` | GET | One CI with its inbound and outbound relationships |
| CMDB Meta API | `/api/now/cmdb/meta/<class>` | GET | The fields and relationship rules of a CI class |
| List export URL | `/<table>_list.do?CSV` (also `?EXCEL`, `?XML`, `?JSONv2`) | GET (browser) | Download a list as a file |

DELETE and PUT are listed for completeness only. Do not use them on SILVA.

## 2. Table API parameters

| Parameter | What it does | Example |
|---|---|---|
| `sysparm_query` | The filter (encoded query) | `name=ts12.hk.intraxa` |
| `sysparm_fields` | Which columns to return. Dot-walking is allowed. | `name,parent.name,parent.used_for` |
| `sysparm_display_value` | `true` returns names, `false` returns sys_ids, `all` returns both | `true` |
| `sysparm_exclude_reference_link` | Removes link objects so the values are plain strings | `true` |
| `sysparm_limit` | Page size (keep it at 10,000 or less) | `1000` |
| `sysparm_offset` | Where the page starts | `1000` |
| `sysparm_no_count` | Skips the total count, which makes big tables faster | `true` |
| `sysparm_input_display_value` | On POST or PATCH, lets you send names instead of sys_ids. Unmatched names are silently dropped. | `true` |
| `X-Total-Count` (response header) | Total rows for the filter | Read it with `curl -I` |

## 3. Encoded query operators (`sysparm_query`)

In a URL, `^` must be written as `%5E` and spaces as `%20`.

| Operator | Meaning | Example |
|---|---|---|
| `=` | Equals | `name=ALJ_EIP_PRD` |
| `!=` | Not equals | `install_status!=7` |
| `LIKE` | Contains | `nameLIKEfscd` |
| `STARTSWITH` | Starts with | `nameSTARTSWITHuk-sap` |
| `ENDSWITH` | Ends with | `nameENDSWITH_PRD` |
| `IN` | One of a list | `u_environmentINProduction,Development` |
| `ISEMPTY` | Field is blank | `support_groupISEMPTY` |
| `ISNOTEMPTY` | Field has a value | `u_environmentISNOTEMPTY` |
| `INSTANCEOF` | Class or any child class | `sys_class_nameINSTANCEOFcmdb_ci_service` |
| `^` | AND | `active=true^nameLIKEAXAJP` |
| `^OR` | OR | `name=ts12^ORfqdn=ts12.hk.intraxa` |
| `^NQ` | New query (OR between whole groups) | `a=1^b=2^NQc=3` |
| `ORDERBY` / `ORDERBYDESC` | Sort | `ORDERBYname` |
| Dot-walk | Filter on a field of a linked record | `parent.name=uk-sap-fscd-dev` |

Tip: build the filter in the SILVA list view, right-click the breadcrumb, and choose "Copy query". That gives you a ready encoded query.

## 4. Common calls by task

### Discovery (find table and field names)

| Line in 32.sh | Call | What you get |
|---|---|---|
| 1 | `sys_db_object` where name contains `service` | Table names and labels |
| 2 | `sys_dictionary` for `service_offering` | Every field name, label and type on offerings |
| 3 | `sys_dictionary` for `cmdb_ci_service` | Every field on business services |
| 4 | `sys_choice` for `incident.u_environment` | Valid Environment labels |

### Hosts, services, offerings and groups

| Line | Call | What you get |
|---|---|---|
| 5 | `cmdb_ci` by name or fqdn | The host record, its class and support group |
| 6 | `svc_ci_assoc` by host name | The business services of one host |
| 7 | `cmdb_rel_ci` where the child is the host | All relationships of the host (backup for line 6) |
| 8 | `cmdb_ci_service` by name | One business service with its support group and Used for |
| 9 | `cmdb_ci_service` where name contains `fscd` | All environment variants of one application |
| 10 | `service_offering` by parent name | The offerings of one business service |
| 11 | `service_offering` for all rows with parent and env | Every environment and service pair |
| 12 | `sys_user_group` by name | Whether a group exists and is active |
| 13 | `sys_user_group` where name contains `AXAJP` | All Japan groups |
| 14 | `sys_user` by name | The user sys_id for assigned_to |

### CMDB Instance and Meta API

| Line | Call | What you get |
|---|---|---|
| 15 | `/cmdb/instance/cmdb_ci_server?sysparm_query=name=...` | The server's sys_id |
| 16 | `/cmdb/instance/cmdb_ci_server/<sys_id>` | The server plus every relationship (services, apps, storage) |
| 17 | `/cmdb/meta/cmdb_ci_service` | The fields of the business service class |

### Counts (Aggregate API)

| Line | Call | What you get |
|---|---|---|
| 18 | Count all offerings | Total number |
| 19 | Offerings grouped by `u_environment` | How many offerings per environment |
| 20 | Offerings grouped by `parent` | How many offerings per business service |
| 21 | `svc_ci_assoc` grouped by `service_id` | How many hosts per business service |

### Whole-table export

| Line | Call | What you get |
|---|---|---|
| 22 | Row count header for `svc_ci_assoc` | How many pages you need |
| 23 | `svc_ci_assoc` page 1 as CSV (dot-walked) | Host to service to group |
| 24 | `service_offering` as CSV | Offering to service to environment |
| 25 | Browser `svc_ci_assoc_list.do?CSV` | The same data from a logged-in browser |
| 26 | Browser `service_offering_list.do?EXCEL` | The offerings as Excel |

### Incidents (what the workflow does)

| Line | Call | What you get |
|---|---|---|
| 27 | GET incident by number | Every field the ticket received |
| 28 | GET incident by `correlation_id` | The INC for a Dynatrace problem. This is how CLOSE finds the ticket. |
| 29 | POST incident (test body) | Creates a test incident. Only run it on purpose. |
| 30 | PATCH incident to Resolved (state 6) | Resolves the incident. Only run it on purpose. |

## 5. Example calls

Find every field name on `service_offering` (line 2):

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/sys_dictionary?sysparm_query=name=service_offering%5EelementISNOTEMPTY&sysparm_fields=element,column_label,internal_type,reference&sysparm_limit=500" | jq -r '.result[] | [.element,.column_label,.internal_type,.reference] | @tsv'
```

Count offerings per environment (line 19):

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/stats/service_offering?sysparm_count=true&sysparm_group_by=u_environment&sysparm_display_value=true" | jq -r '.result[] | [.groupby_fields[0].display_value, .stats.count] | @tsv'
```

One host with all relationships (lines 15 and 16):

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/cmdb/instance/cmdb_ci_server?sysparm_query=name=ts12.hk.intraxa" | jq '.result'
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/cmdb/instance/cmdb_ci_server/__SERVER_SYS_ID__" | jq '.result | {name: .attributes.name, outbound: [.outbound_relations[] | {type: .type.display_value, target: .target.display_value}], inbound: [.inbound_relations[] | {type: .type.display_value, target: .target.display_value}]}'
```

## 6. Reading errors

| Response | What it means | What to do |
|---|---|---|
| 200 with `"result": []` | Nothing matched, or ACLs hide the rows | Test the same filter in the browser. If rows show there, ask for read access. |
| 400 | Bad query or field name | Check the field name with line 2 or 3. |
| 401 | Wrong user or password | Check the credentials. |
| 403 | No permission on that table or API | Ask the SILVA admin for read access (and CMDB API access for lines 15–17). |
| 429 | Too many requests | Slow down and use bigger pages instead of many calls. |
| A field is missing from the result | The field name is wrong, or it is hidden by a field ACL | Check with `sys_dictionary`. |

## Data flow map

```
Discovery (sys_db_object, sys_dictionary, sys_choice)
        │ exact table + field names
        ▼
Table API GET ── cmdb_ci ──► svc_ci_assoc / cmdb_rel_ci ──► cmdb_ci_service ──► service_offering
        │                                                        │                    │
        │                                               support_group        environment
        ▼                                                        ▼                    ▼
Aggregate API (counts per env / service)            sys_user_group            sys_choice labels
        │
        ▼
CSV exports ──► join / pivot scripts (seq 30, seq 31) ──► SYSTEM_MAP in the OPEN YAML
        │
        ▼
Workflow: POST incident ──► GET by correlation_id ──► PATCH Resolved
```

## Related files

| File | Purpose |
|---|---|
| `32.sh` | All 30 API one-liners plus the browser links |
| `../29-get-host-info-from-silva/` | Looking up one host step by step |
| `../30-export-whole-silva-mapping-table/` | Whole host to service to offering table |
| `../31-env-business-service-pairs/` | Environment and business service pairs |

## Commands

All commands are in `32.sh`, in the same order as the tables above. Replace `__SNOW_PASSWORD__`, `__SERVER_SYS_ID__` and `__INCIDENT_SYS_ID__` before running.
