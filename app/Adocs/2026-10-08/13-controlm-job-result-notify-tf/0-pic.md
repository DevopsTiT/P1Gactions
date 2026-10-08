# Control-M Job Result Notify Pic

```
activejobs: Ended OK or Ended not OK, ended < 10 min ago, not -F or -S
 → one row per run (order_id + isn)
 → abended in last 24 h (controlm_alert)?
    no  → drop
    yes → TITLE 正常終了 or 異常終了, BODY → 1 problem per run → email
 10 min later → problem closes
```
