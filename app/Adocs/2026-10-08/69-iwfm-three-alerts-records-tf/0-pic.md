# IWFM Three Alerts Pic

```
3 IWFM Splunk alerts → already on 10-05 seq 32 (old analyzer) → rebuild as Records
 EIP006      → 1 min, failures > 2     → high
 Compass     → 5 min, exceptions > 15  → medium
 IWFM_Errors → 1 h, errors > 0         → medium
 all email only → pagerduty "0"
 seq 32 applied? → destroy it first
```

```
log lines → count in window → over threshold? → problem → email route
                                 no → problem closes
```
