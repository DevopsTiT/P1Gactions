# IWFM Alerts Investigation

| Screenshot | Alert | Search | Window and schedule | Trigger | Action |
|---|---|---|---|---|---|
| 1 | EIP - IWFM : EIP006 service Failure Alert | index=eip1015, eip_mediator_serverlog, GenerateFormImage-v2, Status=FAILURE | Last 1 minute, every minute | > 2, no throttle | Email alj_jp_dl_infra_mwss, High |
| 2 | [Prod]ALJ-Compass-IWFMReportException発生 | index=compass-prod-axa-li-jp "IWFMReportException" | Last 5 minutes, every 5 minutes | > 15, no throttle | Email compass IT member and an aog list, Normal |
| 3 | IWFM_Errors | index=iwfm fmwsagentlog, LOGLEVEL Caution or Fatal, transaction | Last 1 hour, hourly at :15 | > 0, throttle 1 hour | Email raju.kolukuluri, Normal |

| Observation | Meaning |
|---|---|
| All three count lines | Detectors fit; no workflow needed |
| Status and LOGLEVEL are Splunk fields | Format in Dynatrace must be checked |
| compass-prod-axa-li-jp | Looks like a Kubernetes namespace |
