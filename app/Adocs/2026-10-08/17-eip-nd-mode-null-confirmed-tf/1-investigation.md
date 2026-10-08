# EIP ND Mode Null Confirmed Investigation

| What I checked | What I found |
|---|---|
| Search text | Same as seq 16. |
| Time range and cron | Last 1 minute, every minute. Same. |
| Trigger | Results greater than 1, Once, no throttle. Same. |
| Action | Email, priority High. Same. |
| Boundary case | A window crossing a 10-minute mark gives 2 timechart rows, but stats count still returns 1 row. |
