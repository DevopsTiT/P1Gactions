# Dynatrace Notebook Tags And Billing Pic

```
Tag query 0 records?
 fieldsAdd tags missing?      → add it in every fetch (J, K)
 tags == "text" on a list?    → in("text", tags) (K)
 case or layout wrong?        → list real tags, compare lower case (J)
 fields name = hosts?         → entity.name (K)

Billing
 per day flat, short ends     → stable host count; partial first and last day (L)
 per host 720                 → on all 30 days (M)
 per host < 720               → part-time host (M2)
```
