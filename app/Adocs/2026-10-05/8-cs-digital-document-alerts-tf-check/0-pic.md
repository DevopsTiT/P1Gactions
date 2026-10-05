# CS Digital Document Alerts Check Pic

```
cs-digital-document-management.tf
  both dynatrace_log_alert           → do not exist → plan fails

  ALERT 1 daily 10:00, last 24h
    → dynatrace_automation_workflow (schedule cron 0 10 * * *, Asia/Tokyo)
    → DQL count → if > 0 → email 4 recipients

  ALERT 2 every 5 min, throttle 1h
    → dynatrace_davis_anomaly_detectors (window 5, dealerting 60)
    → "error" caseSensitive false, minus "delivery not possible"
    → problem → email workflow → aij_jp_dl_csdigitaldocument
```
