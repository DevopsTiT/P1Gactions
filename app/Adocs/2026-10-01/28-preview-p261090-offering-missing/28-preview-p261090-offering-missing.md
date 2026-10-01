# PREVIEW P-261090 Offering Missing

## Decision tree

```
P-261090 (ts12.hk.intraxa, Windows, HK)
  15 of 16 fields OK
  Service Offering (cmdb_ci) MISSING → decision SKIP → no incident, no page   (safe behaviour ✔)
    why missing?
      host CI ts12 → cmdb_rel_ci (Depends on) → Distr-Windows-OS-JumpServer-AGO
      that service has no offering
      no group-based offering for InfraSupport_Dist-WindowsHK_L2_ASIA either
    human ticket INC30340215 (same host) used a different service (37273dbc…) and offering (cfbf255f…)
  fix (done): if the first CI service has no offering, try the CI's other services that have offerings
  re-import PREVIEW v7.1, rerun → expect cmdb_ci filled, or run 28.sh to see what ts12 is linked to
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the workflow behaving correctly? | Yes. It refused to create an incident without a Service Offering. |
| Is the result usable? | Not yet. No incident would be created for this problem. |
| Root cause | The first service linked to ts12, Distr-Windows-OS-JumpServer-AGO, has no offering. |
| What changed? | Task 2 now collects every service linked to the host CI and switches to one that has offerings. |
| Applied to | PREVIEW v7.1 (seq 23), OPEN v7 (seq 17), TEST v7 (seq 4). |

## Summary

Every field except the Service Offering is right, including the host CI, which matches the human ticket INC30340215. The workflow picked the first service linked to the host, and that service has no offering, so OPEN would skip. I changed task 2 to try the host's other linked services when that happens. Re-import and rerun to confirm, or run `28.sh` to see the host's links directly.

## Input (key tags)

| Tag | Value | Used for |
|---|---|---|
| AGO_AXAENVIRONMENTNAME | Development | Environment (first priority) |
| env and AGO_AXAPATCHENVIRONMENT | ACC and ACCEPTANCE | Lower priority, not used |
| AGO_AXA_SUPPORTGROUP | InfraSupport_Dist-WindowsHK_L2_ASIA | Assignment group |
| AGO_OPCOTRIGRAM | ATK | PagerDuty component |
| AGO_DOMAIN | hk.intraxa | Host search domain |
| host | ts12 | Host CI |
| Maintenance tag | none | Maintenance off |

## Result per field

| Field | Value | Verdict |
|---|---|---|
| caller_id and u_on_behalf_of | 8ddef691…dcbc | OK |
| contact_type | event | OK |
| company | b949afc1…0e92 (AXA GROUP OPERATIONS) | OK, from the service. The legal entity tag says AXA-GROUP-OPERATIONS-HONG-KONG, so confirm. |
| u_environment | Development (tag AGO_AXAENVIRONMENTNAME) | OK, same as INC30340215 |
| u_business_service | aff6dd5f…cbd3 (Distr-Windows-OS-JumpServer-AGO), via ts12 cmdb_rel_ci Depends on | Questionable. INC30340215 used 37273dbc… |
| cmdb_ci (Service Offering) | empty, "service offering: not found" | MISSING, so the decision is SKIP |
| u_configuration_item | 1dfdcf8a…1941 (ts12.hk.intraxa) | OK, same as INC30340215 |
| category, subcategory, impact, urgency | other, other, 4, 4 | OK |
| assignment_group | 633d558e…e5d (InfraSupport_Dist-WindowsHK_L2_ASIA), tag AGO_AXA_SUPPORTGROUP | OK |
| short_description | [DYNATRACE JAPAN][ts12.hk.intraxa] - Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa | OK |
| correlation_id | P-261090 | OK |
| duplicate_check | HTTP 200, none | OK |
| open_v7_would | SKIP (missing: cmdb_ci (Service Offering)) | Correct for this data |

PagerDuty: 5 of 5 checks OK. NOT send for the same reason. Severity error, component ATK, group Development, dedup_key dt-problem-P-261090.

## The fix in task 2

| Before | After |
|---|---|
| For each host CI, take only the first linked service. | Collect every linked service: CI fields, all svc_ci_assoc rows, all service parents in cmdb_rel_ci. |
| If that service has no offering, the offering stays empty. | If the chosen service has no offering, switch to the next linked service that has offerings. |
| No visibility of other links. | New output `ci_services` lists every service linked to the CI and how. |

The method text shows the switch, e.g. `CI ts12.hk.intraxa -> cmdb_rel_ci (Depends on::Used by) -> switched to <name> via ... (Distr-Windows-OS-JumpServer-AGO has no offering)`.

If ts12 has no other linked service with offerings, the result will still be SKIP. Then the choice is a business decision: map this support group to a service in SERVICE_MAP, or ask the CMDB team to link ts12 to the right service.

## Data flow

```
tags → host ts12, group InfraSupport_Dist-WindowsHK_L2_ASIA, env Development
  → cmdb_ci ts12.hk.intraxa (1dfdcf8a…)
  → linked services (new: all of them)
      Distr-Windows-OS-JumpServer-AGO → no offering → skip it
      next linked service with offerings → use it
  → offering for Development (or first) → cmdb_ci filled → decision create
```

## Related files

| File | Purpose |
|---|---|
| `23-preview-v7-1-no-post-first/23-preview-v7-1-no-post-first.workflow.yaml` | Re-import this (updated). |
| `17-open-v7-silva-pagerduty/` | OPEN v7, same fix. |
| `4-v7-test-extraction-validate/` | TEST v7, same fix. |
| `28.sh` | Queries to see what ts12 is linked to and compare with INC30340215. |

## Commands

See `28.sh`. Line 1 lists every service ts12 depends on. Line 3 confirms Distr-Windows-OS-JumpServer-AGO has no offering. Lines 4 and 5 show what INC30340215 used and that service's offerings.
