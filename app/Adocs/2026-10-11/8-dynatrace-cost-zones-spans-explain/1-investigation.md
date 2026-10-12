# Cost Result, Management Zones And Spans Investigation

| Item | Evidence on screen |
|---|---|
| Cost query end | lookup on event.type with prefix ratecard., cost = usage × price, fieldsRename, fieldsKeep, 1,000 rows, all EIP, cost "< 0.01" |
| Cost rows | Log Ingest billed_bytes about 10,000, price 0.0948; Log Retain about 3 million, price 0.000332 |
| Zones | Blurry; fetch host, expand managementZones, 1,000 rows with repeated names |
| Spans | fetch spans, one service, makeTimeseries count by endpoint.name, top 10, 7 days, daily waves |
