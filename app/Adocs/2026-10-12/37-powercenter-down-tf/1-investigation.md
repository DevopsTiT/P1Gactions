# Powercenter Down Investigation

| What was checked | Finding |
|---|---|
| Alert | Powercenter down |
| Description | This alert will be created when powercenter is down |
| Search | `index="powercenter" ISP_MASTER_ELECT_LOCK` |
| Schedule | Cron `*/1 * * * *`, last 1 minute |
| Trigger | More than 3 results, once |
| Throttle | Off |
| Action | Email only, Normal. Recipients not copied. |
| Overlap | Same search as answers 35 and 36. |
