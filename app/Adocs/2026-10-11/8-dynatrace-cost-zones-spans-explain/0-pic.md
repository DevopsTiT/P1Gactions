# Cost Result, Management Zones And Spans Pic

```
Cost query end → rate card lookup → usage × price → 1,000 rows of "< 0.01" EUR
  → summarize by capability or day; EIP log volume tiny (check C3)
Zones → expand managementZones → repeats, no counts → summarize by zone, find hosts with none
Spans → one service, top 10 endpoints, 7 days → midday peaks, quiet nights
  → use dt.service.request.count (faster, cheaper)
```
