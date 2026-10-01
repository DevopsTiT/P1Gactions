# Input To cmdb_ci Mapping

## Decision tree

```
Does the P-261090 input name the offering or business service?
  no tag like snow-service / u_business_service / offering → cannot read cmdb_ci directly
  use the input as keys into SILVA instead
    host:ts12                       → host CI → incidents on that CI → most used offering   (workflow: history step)
    AGO_AXA_SUPPORTGROUP            → offerings owned or supported by that group            (workflow: improved group step)
    AGO_AXAENVIRONMENTNAME:Development → pick the Development offering among candidates
    description "EPAS"              → hint only, manual check (32.sh line 4)
  none of them works → SERVICE_MAP or CMDB fix
```

## Short takeaway

| Question | Answer |
|---|---|
| Can cmdb_ci come straight from the input? | No. No tag names a business service or offering. |
| Which input values lead to it? | host ts12, the support group tag, and the environment tag. |
| What does the workflow do now? | Tries the host's incident history first, then offerings of the support group (assignment or support group). |
| What changed this time? | The group step now also matches the offering's support_group, and uses the group sys_id when known. |
| How to know before running? | Run 32.sh lines 1 to 3. Any non-empty result means the workflow will find an offering. |

## Summary

The input describes the host and the team, not the service. The workflow can still reach the offering through SILVA: the host's earlier incidents, or offerings tied to the support group. I widened the group step so it checks both group fields on the offering.

## What each input value gives

| Input value | SILVA field it fills | How |
|---|---|---|
| host:ts12 and AGO_DOMAIN:hk.intraxa | u_configuration_item | cmdb_ci name ts12.hk.intraxa (already working) |
| host:ts12 | cmdb_ci (offering), u_business_service | Incident history on that host CI (new step from seq 31) |
| AGO_AXA_SUPPORTGROUP:InfraSupport_Dist-WindowsHK_L2_ASIA | assignment_group | sys_user_group by name (already working) |
| AGO_AXA_SUPPORTGROUP | cmdb_ci (offering) | Offerings whose assignment_group or support_group is this group (improved now) |
| AGO_AXAENVIRONMENTNAME:Development | u_environment, offering choice | Environment label, and the Development offering wins when several match |
| AGO_AXAATSLEGALENTITY:AXA-GROUP-OPERATIONS-HONG-KONG | company (check only) | Workflow uses the service company. 32.sh line 6 shows the Hong Kong company if it differs. |
| AGO_AXAOPCOTRIGRAM:ATK | PagerDuty component | Already used |
| [INFRA.ACC] Windows System | app code INFRA | Weak, only used in searches |
| event.description mentions EPAS | none automatically | Hint for a manual check (32.sh line 4) |
| maintenance.is_under_maintenance false, no AGO_Maintenance tag | decision | Maintenance off |

## Order the workflow now uses for the offering

| Order | Source | Fires for P-261090? |
|---|---|---|
| 1 | Offering of the chosen service for the environment | No. Technical service. |
| 2 | Offering found by the service search | No. |
| 3 | Incident history on the host CI | Yes if 32.sh line 1 returns rows. |
| 4 | Default set | No. A group tag exists. |
| 5 | First offering of the chosen service | No. None exist. |
| 6 | Offerings of the group (assignment or support group) | Yes if 32.sh line 2 returns rows. |

## Data flow

```
input
  host ts12 ──→ cmdb_ci ts12.hk.intraxa ──→ incidents on ts12 ──→ offering + parent service
  support group ──→ sys_user_group ──→ offerings (assignment_group or support_group)
  environment Development ──→ choose the Development offering
→ cmdb_ci + u_business_service → decision create
```

## Related files

| File | Purpose |
|---|---|
| `30-preview-then-post-v7-1/30-preview-then-post-v7-1.workflow.yaml` | Updated. Re-import. |
| `29-…`, `23-…`, `17-…`, `4-…` workflows | Same change. |
| `31-how-to-get-cmdb-ci-offering/` | The history step. |
| `32.sh` | Queries that test each path. |

## Commands

See `32.sh`. Line 1 is the host history path. Line 2 is the group offering path. Line 3 shows offerings this group used on past incidents. Line 4 checks EPAS offerings. Line 5 shows the INC30340215 offering. Line 6 checks the Hong Kong company.
