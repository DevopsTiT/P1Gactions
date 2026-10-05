# Investigation

| What was checked | Finding |
|---|---|
| Screenshot from the previous question | A CUSTOM_ALERT problem for eventID 258 on TS12.hk.intraxa, so an equivalent rule already exists |
| Splunk alert text | Not provided; assumed the common `WinEventLog:Application EventCode=258` search |
| Dynatrace field names | Usual OneAgent names are `log.source`, `winlog.eventid`, `winlog.provider`, `loglevel`; to be confirmed with the Step 1 query |
| Routing | Host tags reach the problem only when the event is linked to the host entity |
