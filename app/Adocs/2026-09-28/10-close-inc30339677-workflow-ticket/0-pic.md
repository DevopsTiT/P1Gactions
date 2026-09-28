# Close INC30339677 Pic

```
INC30339677 (correlation_id P-260915247)
   │
   ├─ Wait / close problem in Dynatrace ──► CLOSE workflow
   │        ├─ SILVA: find by correlation_id → PATCH state 6 → Resolved
   │        └─ PagerDuty: resolve dt-problem-P-260915247
   │
   ├─ CLOSE ran, INC still New?
   │        ├─ found=false → correlation_id field empty on INC
   │        ├─ 401 → password
   │        ├─ 403 → API user lacks write
   │        └─ network → allowlist silvastg.service-now.com
   │
   └─ Manual SNOW resolve → also resolve PagerDuty by hand
```
