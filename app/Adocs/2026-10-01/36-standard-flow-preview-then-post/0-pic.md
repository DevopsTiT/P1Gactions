# Standard Flow Pic

```
Problem trigger
   ▼
extract-event-tags ─► resolve-snow-values ─► build-payload
                                                ├─► preview-silva-incident ─► post-silva-incident
                                                └─► preview-pagerduty ─────► trigger-pagerduty

Draft? ─► Save / Deploy ─► trigger active
Change? ─► copy standard YAML ─► new numbered folder
```
