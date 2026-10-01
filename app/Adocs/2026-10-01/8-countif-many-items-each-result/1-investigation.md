# Investigation

| What was checked | Evidence |
|---|---|
| User query | host group `HOST_GROUP-551B8509BA489285`, `summarize log_count = countIf(contains(log.source, "/opt/app/Calculator/Log/CalcServer.log", caseSensitive: false))`, then YES/NO and code |
| Result | 1 record, Last 7 days, 465.66 GiB scanned |
| Pic2 | Items from `/app/ICM_CPW/log/ap/default.log` to `/var/opt/universal/log/unv.log` visible |
| Design | Keep the user's countIf style; add record/expand to get one row per item |
| Cost note | Scan size depends on timeframe and host group, not on the number of countIf items |
