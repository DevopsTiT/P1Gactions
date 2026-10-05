# PMT API Alerts Check Pic

```
pmt-api.tf (9 × dynatrace_log_alert → plan fails)
  alert 2 parse LD LD LD LD NUMBER → wrong number → LD 'Max Memory Used: ' INT
  alerts 6 = 7                     → delete 6
  throttle 60 SECONDS              → no effect; meant 60 minutes?
  alert 3 LAST_6_MINUTES           → overlap; detector fixes
  $name$, "Optional"               → event.name, real descriptions
  recipients                       → pa, pa_koichi, adept, none
  → 8 detectors (for_each) + 3 email workflows (for_each)
```
