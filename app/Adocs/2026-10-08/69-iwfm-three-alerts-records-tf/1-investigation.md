# IWFM Three Alerts Investigation

| What I checked | What I found |
|---|---|
| Earlier conversions | 2026-10-05 seq 32 covered all three with the static threshold analyzer and makeTimeseries. |
| EIP006 search | eip1015, eip_mediator_serverlog, GenerateFormImage-v2, Status=FAILURE |
| EIP006 trigger | Last 1 minute, more than 2 results, priority High |
| Compass search | compass-prod-axa-li-jp, "IWFMReportException" |
| Compass trigger | Last 5 minutes, more than 15 results, priority Normal |
| IWFM search | iwfm, fmwsagentlog, LOGLEVEL Caution or Fatal, transaction by host and AGENTID |
| IWFM trigger | Hourly at :15, last 1 hour, more than 0 results, throttle 1 hour, priority Normal |
| PagerDuty | None of the three has a PagerDuty action |
