# CountIf Many Items Picture

```
1 item works → many items?
 ├─ wide row OK      → A: cNN countIf + rNN YES/NO
 ├─ row per item     → B: cNN countIf → array(record) → expand → fieldsFlatten
 └─ lighter compute  → C: by log.source → sum(if) → same as B
```
