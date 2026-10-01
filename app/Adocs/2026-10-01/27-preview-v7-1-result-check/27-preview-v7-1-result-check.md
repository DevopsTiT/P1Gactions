# PREVIEW v7.1 Result Check

## Decision tree

```
PREVIEW v7.1 on P-260916434
  workflow version?  PD link = Dynatrace problem, routing_key "__hidden__ (set in OPEN v7 …)" → new parallel v7.1 ✔
  16 SILVA fields?   all OK, problems [] ✔
  duplicate?         HTTP 200, none ✔
  PagerDuty body?    5 checks OK, ready true ✔
  ready false?       only because decision = maintenance on (tag AGO_Maintenance:True)
  warnings to confirm
    offering         "first offering … environment NOT matched" → Production - Gold for Integration / Test
    business service found by search with score 5 (the minimum), not through the host CI
    host CI name     "deaa310b.prprivmgmt.intraxa_2023-08-23 06:00:36" → looks like a renamed duplicate CI
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the workflow working? | Yes. Every task ran, all 16 fields are OK, and PagerDuty is ready. |
| Is it the new version? | Yes. The PagerDuty link points to the Dynatrace problem, so this is the parallel v7.1. |
| Why ready false? | Only the maintenance rule: entity tag AGO_Maintenance:True. |
| Anything wrong in the data? | Three warnings: the offering environment, a weak business service match, and a suspicious host CI name. |

## Summary

The workflow works end to end and sends nothing. The data is complete and correctly shaped. Before turning on OPEN v7, three values need a human check in SILVA, because each one could put the ticket on the wrong service, offering or host.

## What passed

| Field | Value | Where it came from |
|---|---|---|
| caller_id | 8ddef691…dcbc | Setting CALLER_SYS_ID |
| u_on_behalf_of | 8ddef691…dcbc | Setting ON_BEHALF_OF_SYS_ID |
| contact_type | event | Setting |
| company | 3e731d56…193f (AXA DIRECT JAPAN) | Business service company |
| u_environment | Integration / Test | Tag AGO_AXAPATCHENVIRONMENT_ORACLE (ACCEPTANCE) |
| u_business_service | 03bd24ce…cbd4 (Data / Analytics) | Search, score 5 |
| cmdb_ci (offering) | 3d62b88e…cba5 (Data / Analytics - AXA DIRECT JAPAN - Production - Gold) | First offering, environment not matched |
| u_configuration_item | 485b4cee…cbeb | Host CI found by host name |
| category and subcategory | other | Settings |
| impact and urgency | 4 | Settings |
| assignment_group | 5223d8c6…cb12 (Database_AXAJP) | Tag AGO_ORACLE_ASSIGNMENT_GROUP |
| short_description | [DYNATRACE JAPAN][deaa310b.prprivmgmt.intraxa] - Oracle DB Instance down | Prefix, host, event name |
| correlation_id | P-260916434 | Problem ID |
| duplicate_check | HTTP 200, no open incident | GET incident |

PagerDuty: event_action trigger, dedup_key dt-problem-P-260916434, severity error, source deaa310b.prprivmgmt.intraxa, group Integration / Test, component ALJ. All five checks OK.

## Warnings to confirm

| # | Warning | Why it matters | How to check |
|---|---|---|---|
| 1 | Maintenance tag blocks the ticket | AGO_Maintenance:True is on this entity. If it is a permanent label, OPEN never creates tickets for it. | Ask the AGO team. Then keep USE_MAINTENANCE_TAG true, or set it false. |
| 2 | Offering is Production - Gold, but the environment is Integration / Test | Data / Analytics probably has no Integration / Test offering, so the workflow took the first one. | 27.sh line 2 lists all offerings of the service. |
| 3 | Business service found by search with score 5 | 5 is the minimum to accept. It came from group, operational and class only, not from the host CI link. | 27.sh lines 3 and 4 show whether the DB or host CI links to a service. |
| 4 | Host CI name ends with "_2023-08-23 06:00:36" | ServiceNow often renames old duplicate CIs this way. The ticket might point at a retired record. | 27.sh line 1 lists every deaa310b CI with install status. Pick the Installed one. |

## Data flow

```
P-260916434 tags
  → task 1: group tag Database_AXAJP, environment ACCEPTANCE → Integration / Test, maintenance tag True
  → task 2: host CI deaa310b…_2023-08-23 (no service link) → search score 5 → Data / Analytics
            → offerings of Data / Analytics → no Integration / Test → first = Production - Gold
  → task 3: 16 fields filled, decision SKIP (maintenance)
  → 4a: all OK, ready false (maintenance)   4b: all OK, NOT send (maintenance)
```

## Related files

| File | Purpose |
|---|---|
| `27.sh` | Queries for warnings 2, 3 and 4. |
| `23-preview-v7-1-no-post-first/` | The workflow that produced this result. |
| `25-info-to-verify-new-workflow/` | Pass rules used for this check. |

## Commands

See `27.sh`.
