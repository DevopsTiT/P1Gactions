# Job Status MyAXA UL Email Copy Investigation

| What I checked | What I found |
|---|---|
| Search | Identical to seq 70 (dedup odate, OrderDate = yesterday) |
| Cron | 25 11 * * 1-6, five minutes before seq 70 |
| Recipients | One person (not copied) |
| Subject | `$result.MSG$ $name$`, word order swapped |
| Message | Same run-day explanation as seq 70 |
