# CCI Timeout Alert Without Summarize Pic

```
Remove summarize?
 yes → raw log lines returned
   any line → problem opens
   aws.log_group identity → one problem, not one per line
   lose count and first/last columns → read log lines on the problem
```

```
Lambda timeout → CloudWatch Logs → Grail → Records detector (raw lines) → problem → workflow → PagerDuty and email
```
