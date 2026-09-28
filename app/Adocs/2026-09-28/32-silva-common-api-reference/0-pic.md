# SILVA API Picture

## Decision tree

```
Need something from SILVA
 ├─ Unknown table or field → sys_db_object / sys_dictionary / sys_choice   (32.sh 1–4)
 ├─ Read records           → Table API GET                                 (5–14)
 ├─ Host + relationships   → CMDB Instance API                             (15–17)
 ├─ Counts / group by      → Aggregate API /api/now/stats                  (18–21)
 ├─ Whole table            → Table API paging or _list.do?CSV              (22–26)
 └─ Incident create/close  → Table API POST / PATCH                        (27–30)
```

## Data flow

```
discovery ──► Table API reads ──► Aggregate counts ──► CSV exports ──► SYSTEM_MAP
                                                                          │
                                                   workflow POST ──► GET by correlation_id ──► PATCH resolved
```
