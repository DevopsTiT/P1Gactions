# Simple Contains Picture

```
fetch logs
 → filter host group
 → filter contains(item1) or ... or contains(item23)
     rows?      → YES, listed by log.source
     0 records  → NO
```
