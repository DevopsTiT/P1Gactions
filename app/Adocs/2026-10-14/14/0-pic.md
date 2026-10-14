# BC2 Index Errors And SSL Pic

## Decision tree

```
index=X → startsWith(src, "X")
#32 → app list + network words → count per app
#41 → parse key=value → count > 1 → sort by date
0 rows? → check query → still 0? → onboarding request
```

## Data flow

```
logs -> src prefix -> phrase filter -> list or count
```
