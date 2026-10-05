# PowerCenter Down Alerts Investigation

| Screenshot | Alert | Time range | Threshold | Priority | Notes |
|---|---|---|---|---|---|
| 1 | 0031_MWSP-PowerCenter-Service-Down-Alert | Last 1 minute | > 2 | Normal | Cron every minute |
| 2 | PowerCenter-ProcessStop | Last 15 minutes | > 0 | High | Cron every minute, description "Optional" |
| 3 | Powercenter down | Last 1 minute | > 3 | Normal | Cron every minute |

| Observation | Meaning |
|---|---|
| Same search in all three | One signal, three alerts |
| No throttle | Repeated emails every minute while lines keep coming |
| 15-minute window every minute | Each line is re-counted for 15 runs |
| Index name only | The Dynatrace field must be confirmed with check.dql |
