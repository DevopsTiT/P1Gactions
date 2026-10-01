# Verify History Offering ts12

## Decision tree

```
P-261090 input: host ts12, group InfraSupport_Dist-WindowsHK_L2_ASIA, env Development, no maintenance
  host CI ts12 (1dfdcf8a…) → only link: Depends on::Used by → Distr-Windows-OS-JumpServer-AGO (technical) → no offering
  offerings owned by the support group? → "No records to display" → group fallback fails
  incident history on ts12 → every ticket uses
      u_business_service 37273dbc… Third Party Services Monitoring Application_02-11-2022 11:25:12
      cmdb_ci           cfbf255f… … - AXA XL - Production - Silver_24-08-2023 17:00:33
  → new history step picks exactly these → cmdb_ci filled → decision create
  confirm: offering is Non-Operational, environment Production (host is Development), company AXA XL
```

## Short takeaway

| Question | Answer |
|---|---|
| Can the workflow get cmdb_ci for P-261090? | Yes, with the history step. Your query proves the data is there. |
| Which offering? | cfbf255f1b03b49416deb166464bcb4b (Third Party Services Monitoring Application … AXA XL - Production - Silver). |
| Which business service? | 37273dbc1b0f7c50114e0826464bcbf8 (Third Party Services Monitoring Application_02-11-2022 11:25:12). |
| Is it what humans used? | Yes. Every ts12 ticket in your result uses this pair and group InfraSupport_Dist-WindowsHK_L2_ASIA. |
| Anything to confirm? | The offering is Non-Operational, its environment is Production, and its company is AXA XL. |

## Summary

Your screenshots confirm the reasoning. The CMDB links ts12 only to a technical service, the support group owns no offering, but the ticket history on ts12 always uses the same business service and offering. The new history step picks that pair, so the next run should fill cmdb_ci and decide create.

## What your evidence shows

| Evidence | Finding |
|---|---|
| Input event | host ts12, AGO_AXA_SUPPORTGROUP InfraSupport_Dist-WindowsHK_L2_ASIA, AGO_AXAENVIRONMENTNAME Development, maintenance false. |
| Incident query on ts12 | INC30340775, INC30340756 and others: u_business_service 37273dbc…, cmdb_ci cfbf255f…, group InfraSupport_Dist-WindowsHK_L2_ASIA. |
| SILVA incident list for ts12 | Many closed EPAS Filter Error tickets, all Business service Third Party Services Monitoring Applic…, same group. One older ticket used SCOM-RDC interface. |
| Offering list by support group | "No records to display". The group fallback cannot work. |
| Offering cfbf255f record | Business Service Third Party Services Monitoring Application, Environment Production, Operational status Non-Operational, Company AXA XL, Support group CAS/TCS App Support - KM. |
| Host CI ts12 record | Windows Server, Environment Development, Support group InfraSupport_Dist-WindowsHK_L2_ASIA, only service link Depends on::Used by Distr-Windows-OS-JumpServer-AGO (Technical Services). |

## Expected new workflow result

| Output | Expected |
|---|---|
| resolve-snow-values offering_history | The ts12 incidents, all with the same offering. |
| service_offering.from | "incident history on host CI (N of N recent incidents)" |
| business_service.from | "CI ts12.hk.intraxa -> cmdb_rel_ci (Depends on::Used by) -> replaced by Third Party Services Monitoring Application… (business service of the history offering)" |
| cmdb_ci | cfbf255f1b03b49416deb166464bcb4b |
| u_business_service | 37273dbc1b0f7c50114e0826464bcbf8 |
| company | The company of 37273dbc (likely AXA XL). Check line 3. |
| decision | create_incident true |
| post-silva-incident | created, or exists if an open ticket already has correlation_id P-261090 |

## Points to confirm

| # | Point | Why it matters | Check |
|---|---|---|---|
| 1 | Offering is Non-Operational | Some SILVA rules block or warn on non-operational offerings. Humans still use it. | Line 2. |
| 2 | Offering environment Production, host Development | u_environment stays Development from the tag. Same mix as human tickets. | Line 4 shows what humans put in u_environment. |
| 3 | Company becomes the business service's company | If it is AXA XL, it may differ from human tickets. | Lines 3 and 4. |

## Data flow

```
ts12 ─ Depends on → Distr-Windows-OS-JumpServer-AGO (technical, no offering)
ts12 ─ incident history → cfbf255f (offering) → parent 37273dbc (business service)
→ payload: u_business_service 37273dbc, cmdb_ci cfbf255f, u_configuration_item 1dfdcf8a, group InfraSupport_Dist-WindowsHK_L2_ASIA
→ decision create → post SILVA ‖ trigger PagerDuty
```

## Related files

| File | Purpose |
|---|---|
| `30-preview-then-post-v7-1/30-preview-then-post-v7-1.workflow.yaml` | Workflow with the history step. |
| `31-how-to-get-cmdb-ci-offering/` | Why the step was added. |
| `32.sh` | Verification queries. |

## Commands

See `32.sh`. Line 1 counts offerings used on ts12 tickets (stats API). Line 2 checks the offering. Line 3 checks the business service and its company. Line 4 shows what humans put in the other fields. Line 5 checks the incident after the workflow posts.
