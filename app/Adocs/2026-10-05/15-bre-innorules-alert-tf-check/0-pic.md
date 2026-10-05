# BRE InnoRules Alert Check Pic

```
innorules.tf (dynatrace_log_alert → plan fails)
  integration_key in file  → remove, rotate, sensitive variable
  cron */5 1-5 * * *       → 01:00–05:59 only; confirm (weekdays = */5 * * * 1-5)
  no throttle              → detector window 5, dealerting 5, PD dedup by problem id
  parse LD SPACE LD SPACE  → run parse-check.dql
  "BRE alert"              → Prod_Life_BRE_InnoRulesError
```
