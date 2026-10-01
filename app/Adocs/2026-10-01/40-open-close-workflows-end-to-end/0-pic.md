# OPEN And CLOSE Pic

```
Problem CREATED ─► OPEN
  extract-event-tags ─► resolve-snow-values ─► build-payload
     ├─► preview-silva-incident ─► post-silva-incident ─► SILVA INC (correlation_id P-xxx)
     └─► preview-pagerduty ─────► trigger-pagerduty ───► PD alert (dt-problem-P-xxx)

Problem CLOSED ─► CLOSE
  prepare-close ─► find-silva-incident ─► build-close-payload
     ├─► preview-silva-close ──────► resolve-silva-incident ─► INC Resolved
     └─► preview-pagerduty-resolve ─► resolve-pagerduty ─────► PD alert resolved
```
