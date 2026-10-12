# eopt Frontend All Hosts Pic

## Decision tree

```
same 3-prefix host filter for both alerts
 plain line → Backend (answer 31)
 JSON line  → Frontend (answer 34)
```

## Data flow

```
eopt pods → Grail → plain ERROR → Backend problem
                  → JSON ERROR  → Frontend problem → workflow → email
```
