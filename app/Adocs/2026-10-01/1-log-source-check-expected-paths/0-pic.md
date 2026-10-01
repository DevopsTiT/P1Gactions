# Log Source Check Picture

```
Q2 result
 ├─ all FOUND → done
 └─ MISSING rows
     ├─ Q1 sources are C:\ D:\ ? → Windows host group, pic2 is Linux → run Q3
     ├─ Q3 shows path under other group → wrong group checked
     └─ Q3 shows nothing → not ingested
          ├─ file not on host → app side
          └─ file on host → log ingest rule / OneAgent log module / permissions
```

```
host file → OneAgent → Grail logs (log.source, dt.entity.host_group)
   → Q1 in_pic2 column
   → Q2 FOUND / MISSING per expected path
   → Q3 host group per expected path
```
