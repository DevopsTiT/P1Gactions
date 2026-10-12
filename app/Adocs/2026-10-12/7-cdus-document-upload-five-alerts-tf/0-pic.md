# CDUS Document Upload Five Alerts Pic

```
5 x dynatrace_log_alert (HIGH + PagerDuty) → 5 x Records detector
 Alert 1 = Alert 5 query → double page → keep one
 Alert 1 "Pending" → actually crash lines → rename or refilter
 Alert 2 action + cmxDocumentId → maybe normal lines → check query 3
 Alert 3 "ETIM" → matches dateTime → use ETIMEDOUT
 PagerDuty key → removed; rotate if committed
```

```
Lambda logs → CloudWatch → Grail → 5 detectors (15m) → problems (high) → workflow → PagerDuty and email
```
