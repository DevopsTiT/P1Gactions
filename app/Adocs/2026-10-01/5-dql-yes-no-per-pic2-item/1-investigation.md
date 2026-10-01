# Investigation

| What was checked | Evidence |
|---|---|
| User query | `fetch logs`, host group `HOST_GROUP-551B8509BA489285`, `contains(log.source, "/opt/app/Calculator/Log/CalcServer.log", caseSensitive: false)` |
| Result | 533 records in 7 days, 3.21 GiB scanned, hosts HOST-67C132A15C522B77 and HOST-AA22E644D9B2F428, app 10790000-Product-Rate-Calculation |
| Pic2 | Same 23 paths, editor lines 271–293 |
| Overlap check | No two pic2 paths contain each other, so `coalesce` labels each file with exactly one item |
| Design | Summarize by `log.source` before the 23 checks to keep it cheap; `append` to show NO rows |
