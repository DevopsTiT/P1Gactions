# Pic — PagerDuty Common Functions

```
Trigger (page) → Ack (I own it) → Investigate → Resolve (stop page)
  │                              │
  Dynatrace OPEN                 Dynatrace CLOSE
  event_action=trigger           event_action=resolve
  same routing_key + dedup_key
```
