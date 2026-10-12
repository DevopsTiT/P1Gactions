# PowerCenter Process Stop Investigation

| What was checked | Finding |
|---|---|
| Alert | PowerCenter-ProcessStop |
| Description | Empty ("Optional") |
| Search | `index="powercenter" ISP_MASTER_ELECT_LOCK` |
| Schedule | Cron every minute, last 15 minutes |
| Trigger | More than 0 results, once |
| Throttle | Off |
| Action | Email only, High. Recipients not copied. |
| Overlap | Same search as answer 35 (Service Down). |
