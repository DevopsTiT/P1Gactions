# Control-M Rerun Check Investigation

| What I checked | What I found |
|---|---|
| Earlier conversions | 10-05 seq 30 made a workflow. 10-05 seq 31/37/38 and 10-07 seq 14 skipped it. |
| Actions | Output to ControlmRerunHistory.csv, and a collapsed Send email |
| Search | activejobs (8 h) + history CSV + controlm_alert (24 h), stats by order_id |
| Condition | Abended, then ended OK, not in the history CSV, abend event exists |
| Schedule | Every 4 minutes, last 8 hours |
| Overlap | Seq 71 reports the same rerun as 正常終了 |
