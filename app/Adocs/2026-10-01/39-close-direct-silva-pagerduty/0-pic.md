# Close Direct Pic

```
Problem CLOSED
   ▼
prepare-close
   ├─► close-silva-incident  GET open by correlation_id → check choices → PATCH Resolved (each)
   └─► close-pagerduty       POST resolve dt-problem-<id>

no open incident   → skipped
close_code invalid → fails, lists allowed values
state not changed  → fails, add EXTRA_FIELDS
```
