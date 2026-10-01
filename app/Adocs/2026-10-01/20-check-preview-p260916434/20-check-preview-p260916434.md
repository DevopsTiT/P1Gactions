# Check PREVIEW Result P-260916434

## Decision Tree

```
PREVIEW run on P-260916434 (Oracle DB DEA10B01 down, host deaa310b)
 │
 ├─ Graph shows preview-pagerduty UNDER preview-silva-incident → old (serial) import → re-import 18 yaml
 │
 ├─ open_v7_would = SKIP (maintenance is on)
 │     cause: entity tag AGO_Maintenance:True (no real maintenance window)
 │     ├─ tag means "skip tickets"      → keep USE_MAINTENANCE_TAG = true
 │     └─ tag is only a label           → set USE_MAINTENANCE_TAG = false
 │
 ├─ Payload keys and sys_ids           → all filled, all sys_id where needed  ✔
 ├─ business service ≠ offering        → 03bd24ce... vs 3d62b88e...           ✔ (seq 9 fix works)
 ├─ Offering = "... - Production - Gold" but environment = Integration / Test → WARN, confirm
 └─ PagerDuty body                      → dedup_key, summary, source, severity OK ✔
```

## Short Takeaway

| Question | Answer |
|---|---|
| Is the data prepared correctly? | Yes, mostly. Every SILVA field is filled with the right key and sys_id format. |
| Why SKIP? | Entity tag `AGO_Maintenance:True`. OPEN v7 would not create a ticket or page. |
| Is that right? | Only if the tag really means "under maintenance". It looks like a static label. |
| What I changed | New setting `USE_MAINTENANCE_TAG` in task 1 of TEST, OPEN and PREVIEW |
| Open point | Environment Integration / Test, but offering is Production |
| Old import | The screenshot is the serial version; re-import the parallel PREVIEW |

## Summary

The prepared SILVA and PagerDuty bodies look right: the business service, offering, host CI, group and caller are all sys_ids, and business service and offering are different records now. The only reason nothing would be sent is the maintenance rule, which fired on the entity tag `AGO_Maintenance:True`. Decide whether that tag should block tickets and set `USE_MAINTENANCE_TAG` accordingly.

## SILVA Payload Check

| Key | Value | Verdict |
|---|---|---|
| caller_id | 8ddef691fb34cf547b0dfe7b4eefdcbc | OK (Dynatrace JP sys_id) |
| u_on_behalf_of | 8ddef691fb34cf547b0dfe7b4eefdcbc | OK |
| contact_type | event | OK |
| company | 3e731d56dba4f6c8a476f9f51d96193f | OK format |
| u_environment | Integration / Test | Confirm (tag AGO_AXAPATCHENVIRONMENT_ORACLE:ACCEPTANCE) |
| u_business_service | 03bd24ce1b477c54688064e4604bcbd4 (Data / Analytics) | OK |
| cmdb_ci | 3d62b88e1b877c54688064e4604bcba5 (Data / Analytics - AXA DIRECT JAPAN - Production - Gold) | OK format, environment mismatch |
| u_configuration_item | 485b4cee1b4d811050b89863b24bcbeb | OK (host CI) |
| category / subcategory | other / other | OK |
| impact / urgency | 4 / 4 | OK |
| assignment_group | 5223d8c61b8f3c54688064e4604bcb12 (Database_AXAJP) | OK, matches AGO_ORACLE_ASSIGNMENT_GROUP |
| short_description | [DYNATRACE JAPAN][deaa310b.prprivmgmt.intraxa] - Oracle DB Instance down | OK |
| correlation_id | P-260916434 | OK |
| duplicate_check | HTTP 200, no open incident | OK |

## PagerDuty Body Check

| Field | Value | Verdict |
|---|---|---|
| dedup_key | dt-problem-P-260916434 | OK |
| summary | Same as short_description | OK |
| source | deaa310b.prprivmgmt.intraxa | OK |
| severity | error | OK |
| component | ALJ | OK |
| custom_details.assignment_group | Database_AXAJP | OK |
| custom_details.business_service | Data / Analytics | OK |
| custom_details.service_offering | Data / Analytics - AXA DIRECT JAPAN - Production - Gold | OK |
| links | `<SILVA incident url>` | Old serial version; parallel version uses the Dynatrace problem link |

## The Maintenance Rule

| Source | Value here | Effect |
|---|---|---|
| Event field `maintenance.is_under_maintenance` | not true | Does not block |
| Entity tag `AGO_Maintenance` | True | Blocks (because USE_MAINTENANCE_TAG = true) |
| Also present | `Test_Maintenance:True` | Not used |

| Setting | Meaning | Choose when |
|---|---|---|
| `USE_MAINTENANCE_TAG = true` | Tag blocks tickets and pages | AGO sets this tag only during real maintenance |
| `USE_MAINTENANCE_TAG = false` | Only a Dynatrace maintenance window blocks | The tag is a permanent label on the entity |

## Environment Versus Offering

| Item | Value |
|---|---|
| Environment from tag | ACCEPTANCE → Integration / Test |
| Offering chosen | ... - Production - Gold |
| Why | Probably the business service has no Integration / Test offering, so the workflow fell back to the first offering |
| Check | resolve-snow-values result → `offering_candidates` lists all offerings of Data / Analytics |

## Data Flow

```
P-260916434 → extract (maintenance tag True) → resolve (service 03bd24ce, offering 3d62b88e, host 485b4cee)
           → build-payload (decision: maintenance is on)
           ├→ preview-silva-incident: SKIP (maintenance is on), payload complete
           └→ preview-pagerduty:      NOT send, body complete
```

## Related Files

| File | What it is |
|---|---|
| `../18-preview-v7-no-post/18-preview-v7-no-post.workflow.yaml` | PREVIEW v7 (parallel + new setting) |
| `../17-open-v7-silva-pagerduty/17-open-v7-silva-pagerduty.workflow.yaml` | OPEN v7 (new setting) |
| `../4-v7-test-extraction-validate/4-v7-test-extraction-validate.workflow.yaml` | TEST v7 (new setting) |
| `20.sh` | Query offerings of Data / Analytics |
