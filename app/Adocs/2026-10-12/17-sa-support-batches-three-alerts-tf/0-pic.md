# Sa Support Batches Pic

## Decision tree

```
sa-support-batches.tf (3 fake blocks)
 Alert 1 "Batch Error" → filter "Task timed out" → duplicate of Alert 3
   real error text known? → change filter
   not known? → delete Alert 1
 Alert 2 "Import Confirmation" → LESS_THAN 2 → absence alert
   summarize count() → filter matches < 2 → JST weekday 08:30 guard
   guard fails? → scheduled workflow 08:30 JST Mon-Fri
   "started" too broad? → remove from filter
 Alert 3 "Task Time Out" → 6 min raw rows → problem
```

## Data flow

```
Lambda sa-support-batches
  → CloudWatch Logs → Grail
  → Alert 1 (6 min, timeout) → problem medium
  → Alert 3 (6 min, timeout) → problem medium  ← duplicate
  → Alert 2 (24 h count < 2, weekday 08:30 JST) → problem medium
  → workflow → email (PagerDuty off)
```
