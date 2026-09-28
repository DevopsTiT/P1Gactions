# Environment And Business Service Pairs

## Decision tree

```
Want: for each application, which business service + offering belongs to each environment
 │
 ├─ Export service_offering with parent + environment (31.sh line 2)
 │    offering_environment filled? → use it (best source)
 │    blank?  → use parent.used_for (the business service's "Used for")
 │    blank?  → read the 3rd part of the offering name
 │               "uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard"
 │                                                          ^^^^^^^^^^^
 │
 ├─ Group rows into one application
 │    strip the env suffix from the business service name
 │    uk-sap-fscd-dev / uk-sap-fscd-prd → uk-sap-fscd
 │    ALJ_EIP_PRD / ALJ_EIP_DEV        → ALJ_EIP
 │
 └─ Run 31-env-service-pairs.py
      → silva_env_pairs_long.csv  (one row per application + environment)
      → silva_env_pairs_wide.csv  (one row per application, one column per environment)
```

## Short takeaway

| Question | Answer |
|---|---|
| Where does SILVA store the environment of a business service? | Mainly on the service offering (the Environment field). The business service's "Used for" field and the offering name are backups. |
| Which table links environment to business service? | `service_offering`. Its Parent field is the business service. |
| How do I know that dev and prd belong to the same application? | Usually by name: the service name minus its env suffix (`-dev`, `_PRD`). If SILVA has an application field, use that instead. |
| How do I get every pair at once? | Export `service_offering` with dot-walked parent columns, then run the pivot script. |

## Summary

In SILVA, each environment usually has its own business service, for example `uk-sap-fscd-dev` for Development and `uk-sap-fscd-prd` for Production. Each business service has one or more offerings, and the offering carries the environment. Export every offering together with its parent service and environment, then group the rows by application name. You get a table showing, for each application, the business service, offering and support group per environment.

## Where the environment lives

| Source | Field | Example | How reliable |
|---|---|---|---|
| Service offering | `u_environment` (Environment) | Development | Best. It is the value the incident form checks against. |
| Business service | `used_for` (Used for) | Development | Good backup when the offering field is blank. |
| Offering name | 3rd part of the name, split by " - " | "... - Development - Standard" | Works because SILVA names offerings with a fixed pattern. |
| Business service name | Suffix | `-dev`, `_PRD` | Use only for grouping, not as the official environment. |

Field names such as `u_environment` are custom fields in this instance. If a column comes back empty, open one offering in SILVA, right-click the Environment label, and choose "Show - 'field name'" to see the real field name.

## How to export (browser)

1. Open `service_offering.list` in SILVA.
2. Use the gear icon to add these columns:
   - Name
   - Environment
   - Support group
   - Company
   - Parent → Name
   - Parent → Used for
   - Parent → Support group
   - Parent → Operational status
3. Optional filter: Parent.Name contains `fscd`, to see a single application.
4. Right-click a column header, choose Export → CSV, and save the file as `silva_offerings_env.csv`.
5. Run `31.sh` line 4 (the pivot script).

## How to export (API)

Line 2 of `31.sh` (replace `__SNOW_PASSWORD__`, not run):

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/service_offering?sysparm_query=ORDERBYparent.name&sysparm_fields=name,u_environment,support_group,company,parent.name,parent.used_for,parent.support_group,parent.operational_status&sysparm_display_value=true&sysparm_exclude_reference_link=true&sysparm_limit=10000" | jq -r '["offering","offering_environment","offering_support_group","company","business_service","service_used_for","service_support_group","service_status"], (.result[] | [.name,.u_environment,.support_group,.company,.["parent.name"],.["parent.used_for"],.["parent.support_group"],.["parent.operational_status"]]) | @csv' > silva_offerings_env.csv
```

| Line in 31.sh | What it does |
|---|---|
| 1 | Counts offerings, so you know if you need a second page |
| 2 | Exports every offering with its parent service and environment |
| 3 | Test for one application only (`fscd`), to check the fields are filled |
| 4 | Runs the pivot script and creates the long and wide CSVs |
| 5 | Exports the list of valid environment labels, to compare against |
| 6 | Opens the offering list in the browser, filtered to `fscd` |

## What the script produces

**Long table** (`silva_env_pairs_long.csv`, one row per application and environment):

| application | environment | business_service | offering | support_group |
|---|---|---|---|---|
| uk-sap-fscd | Development | uk-sap-fscd-dev | uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard | (from SILVA) |
| uk-sap-fscd | Integration / Test | uk-sap-fscd-tst | (from SILVA) | (from SILVA) |
| uk-sap-fscd | Production | uk-sap-fscd-prd | (from SILVA) | (from SILVA) |

**Wide table** (`silva_env_pairs_wide.csv`, one row per application):

| application | Production | Integration / Test | Development |
|---|---|---|---|
| uk-sap-fscd | uk-sap-fscd-prd | uk-sap-fscd-tst | uk-sap-fscd-dev |
| ALJ_EIP | ALJ_EIP_PRD | (blank if none) | (blank if none) |

The rows above only illustrate the layout. The real names come from your export.

How the script decides:

| Step | Rule |
|---|---|
| Environment | Uses the offering's Environment. If blank, uses the service's Used for. If still blank, uses the 3rd part of the offering name. |
| Application | The business service name with a trailing env suffix removed (`-dev`, `-prd`, `-prod`, `-tst`, `-test`, `-int`, `-stg`, `-uat`, `-qa`, with `-` or `_`). |
| Several offerings in one env | All are kept in the long table. The wide table shows the first one and marks the cell with `(+n more)`. |
| Environment normalisation | Values such as Test or Integration-Test are mapped to the SILVA label `Integration / Test`. Prod becomes Production and Dev becomes Development. |

## How to use it in the workflow

Today `SYSTEM_MAP` holds one business service per system. With the long table, you can fill it per environment. This is a suggestion, not applied to the YAML yet:

```js
const SYSTEM_MAP = {
  EIP: {
    Production:           { businessService: "ALJ_EIP_PRD", serviceOffering: "<from table>", l2Group: "<from table>" },
    "Integration / Test": { businessService: "<from table>", serviceOffering: "<from table>", l2Group: "<from table>" },
  },
};
```

The workflow already works out the environment from the `AGO_AXAENVIRONMENTNAME` tag. It would then pick `SYSTEM_MAP[system][environment]`.

## Data flow map

```
cmdb_ci_service (uk-sap-fscd-dev, used_for=Development) ◄──parent── service_offering (Environment=Development)
cmdb_ci_service (uk-sap-fscd-prd, used_for=Production)  ◄──parent── service_offering (Environment=Production)
                                    │
                    export offerings with parent.* columns (31.sh line 2)
                                    ▼
                         silva_offerings_env.csv
                                    ▼
                  31-env-service-pairs.py (environment + application stem)
                        ├──► silva_env_pairs_long.csv
                        └──► silva_env_pairs_wide.csv
                                    ▼
                  SYSTEM_MAP[system][environment] in the OPEN YAML
```

## Related files

| File | Purpose |
|---|---|
| `31.sh` | Export and pivot commands (not run) |
| `31-env-service-pairs.py` | Builds the long and wide environment tables |
| `../30-export-whole-silva-mapping-table/` | Host to service to offering, whole table |
| `../28-how-env-service-group-derived/` | How the workflow picks env, service and group |

## Commands

See `31.sh`. Quick test on one application first:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/service_offering?sysparm_query=parent.nameLIKEfscd&sysparm_fields=name,u_environment,parent.name,parent.used_for&sysparm_display_value=true&sysparm_exclude_reference_link=true" | jq '.result'
```
