# V6 Logic Pic

```
EVENT
 └─ TASK 1 extract (event only)
      ├─ tags split
      ├─ group candidates
      ├─ service tag
      ├─ environment
      ├─ maintenance
      └─ host, DB, db type, trigram, region
 └─ TASK 2 SILVA GET
      ├─ group: map → tag checked → tag name
      ├─ service: map → CI link → scored search → first answer
      ├─ both missing → default set
      ├─ offering, company, CI
 └─ TASK 3 build + decide
      ├─ SNOW body, PagerDuty body
      ├─ form check
      └─ create_incident?
 └─ TASK 4 SILVA
      ├─ skipped / exists / dry_run
      └─ created
 └─ TASK 5 PagerDuty
      ├─ skipped / dry_run
      └─ triggered
```
