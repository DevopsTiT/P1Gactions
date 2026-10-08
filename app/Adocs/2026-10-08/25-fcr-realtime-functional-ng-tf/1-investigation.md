# FCR NG Investigation

| What I checked | What I found |
|---|---|
| Search body | Same as Cockpit360 ALL (seq 22) and Compass (seq 24). |
| Application | "FCR". |
| Schedule | cron */1, Last 2 hours. |
| Trigger | event > 0 or recovery, results > 0, Once. |
| Action | Alert Status Manager, Production; PagerDuty not visible. |
