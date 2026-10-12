# PowerCenter Service Down Investigation

| What was checked | Finding |
|---|---|
| Alert | 0031_MWSP-PowerCenter-Service-Down-Alert |
| Description | This alert will trigger after detecting the service down from Powercenter server. |
| Search | `index="powercenter" ISP_MASTER_ELECT_LOCK` |
| Schedule | Cron every minute, last 1 minute |
| Trigger | More than 2 results, once |
| Throttle | Off |
| Action | Email only, Normal. Recipients not copied. |
| Host or source | Not shown. Check query 1 finds them. |
