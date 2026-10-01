# Verify Queries For P-261090 Offering

## Decision tree

```
Goal: prove the workflow can fill cmdb_ci (offering) for ts12.hk.intraxa
 Step A  Is the host CI right?            → query 1 → name ts12.hk.intraxa, status operational
 Step B  Does incident history help?      → query 2 and 3
          rows with cmdb_ci?  → YES → history fallback will fire → go to Step D
          empty?              → go to Step C
 Step C  Does the support group own offerings? → query 5, 6, 7
          rows?               → group fallback will fire → go to Step D
          empty?              → workflow cannot find it → SERVICE_MAP or CMDB fix
 Step D  Is the offering valid?            → query 4 → operational, parent = business service
 Step E  Environment and company           → query 8 and 9
 Step F  Rerun seq 30 (PREVIEW then POST)  → compare build-payload with Steps B to E
 Step G  After POST                        → query 10 and 11 → incident has cmdb_ci filled
```

## Short takeaway

| Question | Answer |
|---|---|
| What do I run first? | Queries 2 and 6. They decide whether cmdb_ci can be found at all. |
| What does "pass" look like? | Query 2 or 6 returns at least one row with an offering. |
| How do I confirm the workflow used it? | The build-payload `cmdb_ci` equals the top offering from query 3 or a row from query 7. |
| How do I confirm the final ticket? | Query 10 shows the new incident with `cmdb_ci` and `u_business_service` filled. |

## Summary

These are read-only GET queries against SILVA staging. Each one checks one link of the chain the workflow follows: host CI, then incident history or support group, then the offering, then its parent business service. Run them before and after rerunning the seq 30 workflow and compare.

## Known values used

| Name | Value | Where it came from |
|---|---|---|
| Host CI sys_id (ts12.hk.intraxa) | `1dfdcf8adb8dfa40251af9971d961941` | P-261090 build-payload |
| Expected offering sys_id | `cfbf255f1b03b49416deb166464bcb4b` | INC30340215 history |
| Support group | `InfraSupport_Dist-WindowsHK_L2_ASIA` | Tag `AGO_AXA_SUPPORTGROUP` |
| Environment | `Development` | Tag `AGO_AXAENVIRONMENTNAME` |

## The queries

All lines are in `33.sh`. Replace nothing except `REPLACE_WITH_PROBLEM_ID` in query 10.

| # | What it checks | Pass looks like |
|---|---|---|
| 1 | Host CI record | Name is `ts12.hk.intraxa`, class is a Windows server, status operational. |
| 2 | Past incidents on this host that had an offering | At least one row with `cmdb_ci` filled. |
| 3 | Which offering appears most often in that history | Top line is the offering the workflow will pick. Expect `cfbf255f…`. |
| 4 | Offering details | `operational_status` is operational and `parent` is a business service (not the technical JumpServer service). |
| 5 | Support group exists | One row, `active` true. Its sys_id is what the workflow uses. |
| 6 | Offerings owned or supported by that group | One or more rows. |
| 7 | Same, but only Development offerings | Row here means the env match will pick it. |
| 8 | Allowed values for `u_environment` | `Development` appears in the list. |
| 9 | Hong Kong company exists | If a row exists, compare it with the company the workflow chose. |
| 10 | Incident created by the workflow (after POST) | One active row, `cmdb_ci` and `u_business_service` filled. |
| 11 | Latest incidents on ts12 created by the integration user | Fallback check if you do not know the problem id. |

Example, query 2:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=u_configuration_item=1dfdcf8adb8dfa40251af9971d961941^cmdb_ciISNOTEMPTY^ORDERBYDESCsys_created_on" --data-urlencode "sysparm_fields=number,cmdb_ci,u_business_service,assignment_group,sys_created_on" --data-urlencode "sysparm_display_value=true" --data-urlencode "sysparm_limit=20" | jq '.result'
```

## Same checks in the browser (no curl)

Log in to silvastg first, then open:

| Check | URL |
|---|---|
| Incident history on ts12 | `https://silvastg.service-now.com/incident_list.do?sysparm_query=u_configuration_item=1dfdcf8adb8dfa40251af9971d961941^cmdb_ciISNOTEMPTY^ORDERBYDESCsys_created_on` |
| Offerings of the support group | `https://silvastg.service-now.com/service_offering_list.do?sysparm_query=assignment_group.name=InfraSupport_Dist-WindowsHK_L2_ASIA^ORsupport_group.name=InfraSupport_Dist-WindowsHK_L2_ASIA` |
| Expected offering | `https://silvastg.service-now.com/service_offering.do?sys_id=cfbf255f1b03b49416deb166464bcb4b` |
| Host CI | `https://silvastg.service-now.com/cmdb_ci.do?sys_id=1dfdcf8adb8dfa40251af9971d961941` |

## What to compare in the workflow run (seq 30)

| build-payload field | Should equal |
|---|---|
| `snow_incident_payload.cmdb_ci` | Top offering from query 3, or a row from query 7 |
| `snow_incident_payload.u_business_service` | `parent` of that offering (query 4) |
| `snow_incident_payload.u_configuration_item` | `1dfdcf8adb8dfa40251af9971d961941` |
| `snow_incident_payload.assignment_group` | sys_id from query 5 |
| `snow_incident_payload.u_environment` | A value from query 8 matching Development |
| `offering_from` (debug) | Starts with `incident history on host CI` or mentions the group |
| `decision.create` | `true` (maintenance is off for this problem) |

## Data flow map

```
P-261090 event
   │ host ts12 + AGO_DOMAIN
   ▼
cmdb_ci (query 1) ── sys_id 1dfdcf8a…
   │
   ├─► incident history (query 2, 3) ── most-used cmdb_ci ─┐
   │                                                      ▼
   └─► support group (query 5) ─► service_offering (6, 7) ─► offering (query 4)
                                                            │ parent
                                                            ▼
                                                   u_business_service
   ▼
build-payload (seq 30 run) ─► POST incident ─► query 10 / 11 confirm
```

## Related files

| File | Purpose |
|---|---|
| `33.sh` | All queries, one per line |
| `../32-input-to-cmdb-ci-mapping/` | Which input value maps to which SILVA field |
| `../30-preview-then-post-v7-1/30-preview-then-post-v7-1.workflow.yaml` | Workflow to rerun |

## Commands

See `33.sh` in this folder. Lines 1 to 11 are the queries above in the same order. Lines 12 and 13 are mirror copies.
