# Yes No Per Item Picture

```
need per-item answer?
 ├─ one row per item → Q1 (YES/NO, 1/0)
 ├─ one wide row     → Q2 (file count, 0 = NO)
 └─ prove it works   → Q3 (CalcServer.log → YES)
```

```
logs → by log.source → coalesce(contains item01..23) → by item
     → append 23 checklist rows → by item → YES/NO + code
```
