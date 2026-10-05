# Investigation

| What was checked | Finding |
|---|---|
| Search | `index=ods sourcetype=oud_service failed` |
| Schedule | Cron `1 4 * * *`, last 24 hours |
| Trigger | More than 0 results, once, no throttle |
| Actions | Triggered alert High, PagerDuty, Send email |
| Description | Empty |
| Routing | Host-based logs allow the problem to carry AGO tags |
