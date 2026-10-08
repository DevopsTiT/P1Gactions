# AG Portal NTTGW Pic

```
jenkins/test alive (168,553 events) → seq 29 template
application "AG Portal NTTGW" → check lookup spelling
30m window → jobs need 2 runs per 30m, else widen to 60m
actions not visible → high, pagerduty "0" (CONFIRM)
→ fails >= 2 and oks == 0 per application+name
```
