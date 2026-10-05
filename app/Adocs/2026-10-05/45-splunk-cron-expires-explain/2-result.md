# Result

| Item | Outcome |
|---|---|
| Cron | Daily 08:00 in the Splunk server's time zone |
| Expires | Fired result kept 24 hours; no effect on firing |
| Dynatrace | Detector has neither; workflow has cron with explicit time zone |

## Next Steps

| Step | What to do |
|---|---|
| 1 | Confirm Splunk server time zone via Next Scheduled Time |
| 2 | Choose detector (real time) or workflow (08:00 list) |
