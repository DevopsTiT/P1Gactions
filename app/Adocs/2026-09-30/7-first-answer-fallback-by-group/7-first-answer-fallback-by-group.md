# First Answer Fallback By Group

## Decision tree

```
Business service still empty after A (map), B (CI link), C (scored search)?
 │
 ├─ D. first answer with known info (cmdb_ci_service)
 │    ├─ assignment_group.nameLIKE<group>   ← your working query
 │    ├─ support_group.nameLIKE<group>
 │    ├─ nameLIKE<trigram>
 │    └─ nameLIKE<db type>
 │         └─ rows found?
 │              ├─ a row name has the environment (e.g. "Integration / Test") → take it
 │              └─ otherwise → take the first row
 │
 ├─ E. still empty → DEFAULT_BUSINESS_SERVICE
 │
 ├─ Service offering
 │    ├─ offering of the service for the environment
 │    ├─ first offering of the service
 │    ├─ first offering owned by the group (environment match first)
 │    └─ DEFAULT_SERVICE_OFFERING
 │
 └─ Company
      ├─ business service company
      ├─ CI company
      ├─ assignment group company
      └─ DEFAULT_COMPANY (AXA GROUP OPERATIONS)
```

## Short takeaway

| Question | Answer |
|---|---|
| What was added? | Step D: a "first answer" search using the group, trigram or DB type |
| Which query is it based on? | Your `cmdb_ci_service?sysparm_query=assignment_group.nameLIKEDatabase_AXAJP` |
| Which row is taken? | The first row whose name has the environment, else the first row |
| What about other empty columns? | Offering and company now also fall back to group-based answers |
| How do I know a fallback was used? | Every block has a `from` field, and `lookup.first_answer_rows` lists all rows |

## Summary

Your query shows that SILVA returns many services owned by Database_AXAJP. v4 now runs this query when the stronger methods fail, and takes the row that matches the environment, or else the first row. Offering and company use the same idea, so the mandatory SNOW fields are filled from real SILVA data before the static default is used.

## What your query returned (Database_AXAJP)

| Service name (from the screenshot) | Environment in name |
|---|---|
| Data / Analytics - AXA DIRECT JAPAN - Production - Gold | Production |
| QuickSuite - BI reports & Data Analytics (AGJ) | none |
| Spotfire services | none |
| Informatica - AXA DIRECT JAPAN - Integration / Test - Gold | Integration / Test |
| Qualys - AXA DIRECT JAPAN - Production - Gold | Production |
| Informatica - AXA DIRECT JAPAN - Non-Prod - Gold | Non-Prod |

For the Oracle event (ACCEPTANCE → "Integration / Test"), step D would pick "Informatica - AXA DIRECT JAPAN - Integration / Test - Gold", because it is the first name containing the environment label. That is a best guess, not a real link. Check `business_service.from` and fix it with `SERVICE_MAP` if needed.

## Full business service order now

| Order | Method | `from` text |
|---|---|---|
| A | SERVICE_MAP or service tag | `SERVICE_MAP` or `tag ...` |
| B | CI link | `CI <name> -> ...` |
| C | Scored search, clear winner | `tag search (score ...)` |
| D | First answer by known info | `first answer by assignment group (name matches environment)` or `(first row)` |
| E | Static default | `default (DEFAULT_BUSINESS_SERVICE)` |

## About your curl error

`curl: (3) URL rejected: Malformed input to a URL function` comes from special characters (spaces, `^`, `&`, `/`) in the URL. Use `-G` with `--data-urlencode` so curl encodes them for you. See `7.sh`.

## Data flow

```
group (Database_AXAJP), trigram (ALJ), db type (ORACLE), environment label
   │
   ▼
cmdb_ci_service  assignment_group.nameLIKE...  → rows
   │ pick env match or first row
   ▼
business_service  ──► service_offering (parent=service, or group)
   │                   company (service → CI → group → default)
   ▼
snow_required → snow_incident_payload → snow_form_check
```

## Related files

| File | What it is |
|---|---|
| `../3-extract-v4-business-service-and-group/3-extract-v4-business-service-and-group.workflow.yaml` | Updated workflow |
| `7.sh` | Encoded versions of the fallback queries |

## Commands

See `7.sh`.
