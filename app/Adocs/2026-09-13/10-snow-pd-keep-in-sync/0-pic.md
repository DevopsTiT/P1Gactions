# Keep ServiceNow and PagerDuty in Sync — Pic

## Decision tree

```
Need SNOW + PD stay aligned?
  │
  ├─ Same Problem open/close?
  │     → Dynatrace orchestrates both
  │     → Problem ID → SNOW correlation_id
  │     → Problem ID → PD dedup_key (dt-problem-<id>)
  │
  ├─ Open?
  │     → Parallel create → cross-link work notes
  │
  ├─ Close?
  │     → Find INC by correlation_id → resolve INC + PD
  │
  └─ Live assignee SNOW↔PD only?
        → Optional native PD↔SNOW product sync
```

## Data flow

```
Problem OPEN → create INC + PD (same keys) → cross-link notes
Problem CLOSED → resolve INC + PD (same keys)
```
