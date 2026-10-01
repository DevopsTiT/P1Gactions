# V7.1 Workflows And ts12 Result

## Decision tree

```
Which file do I import?
 Want to see data only, nothing sent?        → ...-preview-no-post.workflow.yaml
 Want preview first, then send under it?     → ...-preview-then-post.workflow.yaml   (recommended)
 Want straight send to SILVA and PagerDuty?  → ...-open-post-both.workflow.yaml
 Want field-by-field extraction checks?      → ...-test-validate.workflow.yaml

After rerun on P-261090 (ts12.hk.intraxa)
 cmdb_ci = cfbf255f… ?            → YES → history step worked
                                  → NO  → check offering_history rows in resolve-snow-values
 u_business_service = 37273dbc… ? → YES → service was replaced by the history offering's parent
 decision.create_incident true ?  → YES → post tasks run (or skip if DRY_RUN true)
```

## Short takeaway

| Question | Answer |
|---|---|
| Why a new folder? | You asked that results go into new folders instead of changing old ones. Old folders stay as they are. |
| What is in here? | The four current v7.1 workflow files plus the ts12 verification result. |
| Which file to import? | `34-v7-1-workflows-ts12-result-preview-then-post.workflow.yaml` |
| Will cmdb_ci be filled for ts12? | Yes. Incident history on the host CI always uses offering `cfbf255f…`. |

## Summary

All future workflow changes and results will be written into a new numbered folder. This folder (seq 34) is the current snapshot: the v7.1 workflows with the tag-key fix, the multi-service CI lookup, and the incident-history offering fallback, plus the result for P-261090.

## Workflow files in this folder

| File | What it does | Copied from |
|---|---|---|
| `34-v7-1-workflows-ts12-result-preview-then-post.workflow.yaml` | Preview tasks, then each send task directly under its preview. Sends only when the preview has no problems. | seq 30 |
| `34-v7-1-workflows-ts12-result-open-post-both.workflow.yaml` | Builds the payload, then sends to SILVA and PagerDuty in parallel. | seq 29 |
| `34-v7-1-workflows-ts12-result-preview-no-post.workflow.yaml` | Shows the prepared SILVA and PagerDuty data. Sends nothing. | seq 23 |
| `34-v7-1-workflows-ts12-result-test-validate.workflow.yaml` | Checks each extracted field and reports OK or MISSING. | seq 4 |

These files contain the SILVA password and the PagerDuty routing key. Do not commit them to a shared repo.

## Result for P-261090 (ts12.hk.intraxa)

| Evidence | What it shows |
|---|---|
| Host CI ts12 | Only linked to the technical service Distr-Windows-OS-JumpServer-AGO, which has no offering. |
| Group offerings | InfraSupport_Dist-WindowsHK_L2_ASIA owns no offerings. |
| Incident history on ts12 | INC30340775, INC30340756 and others all use the same offering and business service. |

### Expected output after rerun

| Field | Expected value | Where it comes from |
|---|---|---|
| `cmdb_ci` | `cfbf255f1b03b49416deb166464bcb4b` (… AXA XL - Production - Silver) | Incident history on host CI |
| `u_business_service` | `37273dbc1b0f7c50114e0826464bcbf8` (Third Party Services Monitoring Application) | Parent of the history offering |
| `assignment_group` | InfraSupport_Dist-WindowsHK_L2_ASIA | Tag |
| `service_offering.from` | `incident history on host CI (N of N recent incidents)` | resolve-snow-values |
| `decision.create_incident` | `true` | build-payload |

### Points to confirm

| Point | Why it matters |
|---|---|
| Offering is Non-Operational | Humans still use it, but check SILVA accepts it without a warning. |
| Offering is Production, host is Development | `u_environment` stays Development from the tag. Only the offering name says Production. |
| Company may become AXA XL | Company comes from the business service. Compare with past ts12 tickets (`34.sh` line 3). |

## Data flow map

```
Davis problem P-261090
   │
   ▼
extract-event-tags ── tags: AGO_AXA_SUPPORTGROUP, AGO-DEFAULT-ASSIGNMENT-GROUP, env
   │
   ▼
resolve-snow-values
   ├─ host CI ts12 (u_configuration_item)
   ├─ CI services → technical service only, no offering
   ├─ group offerings → none
   └─ incident history on ts12 → offering cfbf255f → parent service 37273dbc
   │
   ▼
build-payload ── decision create_incident true
   │
   ├─► preview-silva-incident ─► post-silva-incident ─► SILVA stg incident
   └─► preview-pagerduty ─────► trigger-pagerduty ───► PagerDuty Events v2
```

## Related files

| File | Purpose |
|---|---|
| `32-verify-history-offering-ts12/` | Earlier evidence for the ts12 history pair (unchanged). |
| `30-preview-then-post-v7-1/` | Original preview-then-post folder (unchanged). |
| `34.sh` | Verification queries for this result. |

## Commands

See `34.sh`. Key lines: line 1 counts offerings on ts12 tickets, line 2 shows the business service company, line 3 shows human ticket fields, line 4 finds the incident created for P-261090.
