# Gov Inquiry System Alerts Check Pic

```
gov-inquiry-system.tf (7 x dynatrace_log_alert → plan fails)
  notices 1,2,3,7 (Biz file summary + counts)   → for_each scheduled workflow */5 → email lines
  notices 5,6 (error file received)             → same workflow (detector only if team wants tickets)
  failure 4 (level:ERROR)                        → detector → problem → email workflow
  parse: WORD:fileName → NSPACE ; 'xCount:' INT → SPACE? INT
  case: ParseErrorFileAndUpdateDB vs ...Db       → caseSensitive: false
eopt-serverless.tf → unchanged, see seq 11
```
