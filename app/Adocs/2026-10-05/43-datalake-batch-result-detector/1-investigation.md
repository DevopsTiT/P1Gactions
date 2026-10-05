# Investigation

| Checked | Evidence |
|---|---|
| Splunk search | `index="batch_monitoring_logs" \| table _time _raw` |
| Trigger | Daily 08:00, Today, results > 0 |
| Action | Email masayuki.yasuda, Normal |
| User request | Dynatrace alert only, no workflow |
| Detector limit | Evaluates every minute; cannot schedule at 08:00 |
