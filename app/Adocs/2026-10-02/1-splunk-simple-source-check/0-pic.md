# Splunk Simple Source Check Pic

```
Is source X in index=aaa?
 quick look            → | tstats count where index=aaa (source="X" OR source="Y") by source
 need yes/no rows      → tstats + appended list + stats + eval found
 huge index, rough     → | metadata type=sources index=aaa | search source IN (...)
 0 rows unexpectedly   → widen time range → check exact path → check index permission
```

```
source list → tstats (metadata only) → group by source → add missing as 0 → found yes/no
```
