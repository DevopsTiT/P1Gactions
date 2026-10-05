# OUD Restart Failed Pic

```
Splunk: index=ods sourcetype=oud_service failed, daily 04:01 over 24 h, High, PD, email
  → find log.source (check.dql 1)
  → detector every minute: matchesPhrase "failed" > 0, by dt.entity.host
  → problem on the OUD host → AGO tags → standard SILVA + PagerDuty
  → email workflow
  (Option B: 04:01 scheduled workflow + createEvent, if once a day is required)
```
