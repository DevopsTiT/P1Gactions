# Pic

```
SILVA creates INC (thin)
Dynatrace problem → collect-context → find INC by correlation_id (retry 30s x6)
  → PATCH [DT-ENRICH] work note + empty u_ fields (skip closed / unchanged)
  → comment INC link on Dynatrace problem (once)
Never touch: priority, group, CI, state, short_description
```
