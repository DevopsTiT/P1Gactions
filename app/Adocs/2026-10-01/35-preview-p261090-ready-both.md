# P-261090 Preview Ready For Both

## Decision tree

```
preview-silva-incident
 ready true, problems [] ?          → YES → SILVA send will run
 duplicate_check open_incident ""   → no open ticket for P-261090 → CREATE
preview-pagerduty
 ready true, 5 checks OK ?          → YES → PagerDuty trigger will run
Did the send tasks run?
 post-silva-incident action created → note INC number → 35.sh line 1
 action skipped (dry run)           → set DRY_RUN false → rerun
 trigger-pagerduty triggered true   → check PagerDuty incident dt-problem-P-261090
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the preview OK? | Yes. Both previews are ready with no problems. |
| Was cmdb_ci found? | Yes. `cfbf255f…` from incident history, 20 of 20 recent incidents. |
| Business service | `37273dbc…` Third Party Services Monitoring Application, replaced by the history offering's parent. |
| Duplicate? | No. The duplicate check returned HTTP 200 and no open incident. |
| Next step | Check the post-silva-incident and trigger-pagerduty results, then run `35.sh`. |

## Summary

The history fallback worked exactly as expected. All SILVA fields are filled and the PagerDuty body passes all checks. The only things left are to confirm the send tasks ran and that company AXA XL matches what humans use on ts12 tickets.

## SILVA preview values

| Field | Value | Source |
|---|---|---|
| caller_id | `8ddef691fb34cf547b0dfe7b4eefdcbc` | Setting CALLER_SYS_ID |
| u_on_behalf_of | `8ddef691fb34cf547b0dfe7b4eefdcbc` | Setting ON_BEHALF_OF_SYS_ID |
| contact_type | event | Setting |
| company | `7b2d27b3dbc13784a80c5487dc9619e4` (AXA XL) | Enrichment company_id |
| u_environment | Development | Tag AGO_AXAENVIRONMENTNAME |
| u_business_service | `37273dbc1b0f7c50114e0826464bcbf8` | CI → cmdb_rel_ci, then replaced by history offering parent |
| cmdb_ci | `cfbf255f1b03b49416deb166464bcb4b` (AXA XL - Production - Silver) | Incident history on host CI (20 of 20) |
| u_configuration_item | `1dfdcf8adb8dfa40251af9971d961941` (ts12.hk.intraxa) | Host CI found by host name |
| assignment_group | `633d658e…` (InfraSupport_Dist-WindowsHK_L2_ASIA) | Tag |
| impact | 4 | Setting |
| urgency | 4 | Setting |
| category | other | Setting |
| subcategory | other | Setting |
| correlation_id | P-261090 | Problem display id |
| used_sample_event | false | Real problem data was used |

## PagerDuty preview values

| Field | Value |
|---|---|
| event_action | trigger |
| dedup_key | dt-problem-P-261090 |
| summary | [DYNATRACE JAPAN][ts12.hk.intraxa] - Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa |
| source | ts12.hk.intraxa |
| severity | error |
| component | ATK |
| group | Development |
| custom_details.business_service | Third Party Services Monitoring Application_02-11-2022 11:25:12 |
| custom_details.service_offering | … AXA XL - Production - Silver_24-08-2023 17:00:33 |

## Small notes (not blockers)

| Note | What it means |
|---|---|
| `custom_details.db_type` is empty | ts12 is a Windows host, not a database, so no DB type tag exists. Harmless. |
| Offering name says Production | The host and incident environment are Development. Same pair humans used on 20 tickets, so acceptable. |
| Company AXA XL | Confirm with `35.sh` line 3 that past ts12 tickets also show AXA XL. |

## Data flow map

```
P-261090 ─► extract-event-tags ─► resolve-snow-values ─► build-payload
                                     │ host CI ts12
                                     │ history → cfbf255f → parent 37273dbc
                                     ▼
              ┌────────────── preview-silva-incident (ready) ─► post-silva-incident ─► SILVA stg INC
              └────────────── preview-pagerduty (ready) ─────► trigger-pagerduty ───► PagerDuty
```

## Related files

| File | Purpose |
|---|---|
| `34-v7-1-workflows-ts12-result/` | Workflow files used for this run (unchanged). |
| `35.sh` | Post-send checks. |

## Commands

See `35.sh`. Line 1 finds the SILVA incident for P-261090. Line 2 shows its key fields by number (replace INC number). Line 3 compares company on past ts12 tickets.
