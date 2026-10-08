# MyAXA NG State Investigation

| What I checked | What I found |
|---|---|
| Jobs | External Check - MyAXA login-check (Login_Check) and External Check - MyAXA (Function_Check). |
| Old result | Newest NG run older than 10 minutes. |
| Current result | From MYAXA_Monitoring.csv, written by another search. |
| Condition | Same result, newer current run, not in maintenance. |
| Schedule | cron */5, Last 60 minutes. |
| Trigger | Results > 0, Once, no throttle. |
| Action | Email, priority Normal. |
