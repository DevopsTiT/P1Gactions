# Close Workflow Pic

```
Problem CLOSED
   ▼
prepare-close ─► find-silva-incident ─► build-close-payload
                                           ├─► preview-silva-close ──────► resolve-silva-incident (PATCH Resolved)
                                           └─► preview-pagerduty-resolve ─► resolve-pagerduty (event_action resolve)

no incident        → SILVA skip, PagerDuty still resolves
already resolved   → SILVA skip
close_code WRONG   → preview lists real values → fix CLOSE_CODE
state not changed  → add EXTRA_FIELDS
```
