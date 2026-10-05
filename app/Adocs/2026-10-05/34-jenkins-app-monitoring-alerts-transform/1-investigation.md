# Jenkins App Monitoring Investigation

| Screenshots | Alert | Range and schedule | Action |
|---|---|---|---|
| 1 and 2 | URL | Last 15 min, every minute | Alert Status Manager, PagerDuty disabled |
| 3 and 4 | URL for MyAXA | Last 15 min, every minute | PagerDuty enabled |
| 5 to 7 | function | Last 120 min, every minute, pager_duty="0" | PagerDuty disabled |
| 8 to 10 | function for AG Portal | Last 2 hours, every minute | PagerDuty enabled |
| 11 to 13 | function for BancaPotal | Last 2 hours, every minute | PagerDuty enabled |
| 14 to 16 | function for Cockpit360 | Last 2 hours, every minute | PagerDuty enabled |
| 17 to 19 | function for Compass | Last 2 hours, every minute, extra メンテナンス中 rex | PagerDuty enabled |
| 20 to 22 | function for Compass PB | Last 2 hours, application Compass AG | PagerDuty enabled |
| 23 to 25 | function for FCR | Last 2 hours, every minute | PagerDuty enabled |
| 26 to 28 | function for ICM | Last 2 hours, every 3 minutes, application Claims ICM | PagerDuty enabled |

| Observation | Meaning |
|---|---|
| Same search body in 8 function alerts | One detector split by application |
| Macros hide state and maintenance logic | Definitions needed |
| PagerDuty keys visible | Not copied |
