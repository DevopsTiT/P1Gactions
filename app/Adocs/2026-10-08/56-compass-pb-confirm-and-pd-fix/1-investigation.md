# CompassPB and PD Fix Investigation

| What I checked | What I found |
|---|---|
| CompassPB search | Same as seq 27. |
| CompassPB window | 2 hours, cron */1. |
| Earlier folders | Seq 19, 20 and 23 created these three; seq 27 fixed them. |
| Seq 52 and 53 | Same logic as seq 27, but pagerduty "0". |
| Seq 27 PagerDuty | Enable for all three. |
