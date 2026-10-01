# How To Get cmdb_ci Offering

## Decision tree

```
cmdb_ci (Service Offering) empty?
  chosen service has offerings for the environment?     → use it
  service came from a search and was an offering?        → use that offering
  NEW: earlier incidents on the same host CI have one?   → use the most-used offering
                                                            and switch the business service to its parent
  default set (no service, no group tag)?                → default offering
  service has any offering?                              → first offering (environment NOT matched)
  group owns an offering?                                → first offering of the group
  nothing?                                               → MISSING → SKIP (fix CMDB or add a map)
```

## Short takeaway

| Question | Answer |
|---|---|
| Why empty for P-261090? | The service from the host link, Distr-Windows-OS-JumpServer-AGO, is a "Technology Management Service". Technical services have no Service Offering. |
| Where does a correct offering exist? | On earlier human tickets for the same host, e.g. INC30340215 (offering cfbf255f…, business service 37273dbc…). |
| What changed? | Task 2 now reads recent incidents on the same host CI and reuses the most common offering. |
| Does the business service change too? | Yes. It becomes the parent of that offering, so service and offering always match. |
| Where applied? | Seq 30 (preview then post), 29 (OPEN), 23 (PREVIEW), 17 and 4. |

## Summary

The host is linked only to a technical service, and technical services do not carry offerings. Humans who raised tickets on ts12 picked a real business service and offering. The workflow now learns from those tickets: it looks at the last 20 incidents on the same host CI that have an offering, picks the most frequent one, and uses its parent as the business service.

## Evidence from your result

| Field | Value | Meaning |
|---|---|---|
| decision | create_incident false, missing cmdb_ci | Would skip. |
| u_business_service | aff6dd5f…cbd3, Distr-Windows-OS-JumpServer-AGO | Found through ts12 cmdb_rel_ci Depends on::Used by. |
| servicenow_enrichment.number | BSN0186416 | The service record. |
| servicenow_enrichment.service_classification | Technology Management Service | Technical service, no offerings. |
| servicenow_enrichment.assignment_group | DISTR_WINDOWS_OS_ENGINEERING | Owner of the technical service. |
| u_configuration_item | 1dfdcf8a…1941 (ts12.hk.intraxa) | Correct host CI, same as INC30340215. |
| assignment_group | InfraSupport_Dist-WindowsHK_L2_ASIA | From tag AGO_AXA_SUPPORTGROUP. Unchanged. |

## The new step (task 2, section 4)

| Step | What it does | SILVA call |
|---|---|---|
| 1 | Runs only when no offering was found by the service. | |
| 2 | Reads the last 20 incidents on the same host CI that have cmdb_ci filled. | `incident` with `u_configuration_item=<host CI>^cmdb_ciISNOTEMPTY^ORDERBYDESCsys_created_on` |
| 3 | Counts each offering and picks the most used. | |
| 4 | Confirms it is a real offering. | `service_offering` with `sys_id=<offering>` |
| 5 | Sets the business service to the offering's parent (or that incident's u_business_service). | `cmdb_ci_service` by sys_id |
| 6 | Shows the source, e.g. "incident history on host CI (3 of 4 recent incidents)". | |

New output in resolve-snow-values: `offering_history` lists the incidents it looked at.

## Expected result for P-261090 after re-import

| Field | Expected |
|---|---|
| cmdb_ci | cfbf255f1b03b49416deb166464bcb4b, the offering used on INC30340215 (if it is the most common on ts12) |
| u_business_service | Parent of that offering, expected 37273dbc1b0f7c50114e0826464bcbf8 |
| u_business_service source | "… -> replaced by <name> (business service of the history offering)" |
| decision | create_incident true (no maintenance tag on this host) |

## If history is empty

| Option | What to do |
|---|---|
| Ask the CMDB team | Link ts12 to the business service, not only to the technical service. |
| SERVICE_MAP in task 2 | Map ATK or the app code to the exact business service name. |
| Accept SKIP | No ticket until the data is fixed. |

## Data flow

```
ts12 host CI ─ cmdb_rel_ci → Distr-Windows-OS-JumpServer-AGO (technical, no offering)
             └ incident history (u_configuration_item = ts12) → most used cmdb_ci → offering
                                                              → parent → business service
→ cmdb_ci filled → decision create → post SILVA + trigger PagerDuty
```

## Related files

| File | Purpose |
|---|---|
| `30-preview-then-post-v7-1/30-preview-then-post-v7-1.workflow.yaml` | Re-import this (updated). |
| `29-open-v7-1-post-both-ends/`, `23-preview-v7-1-no-post-first/` | Same change. |
| `31.sh` | Queries to preview what the history step will find. |

## Commands

See `31.sh`. Line 1 shows the incidents on ts12 that the new step reads. Line 2 shows the INC30340215 offering and its parent. Line 3 compares the two services. Line 4 lists all ts12 links.
