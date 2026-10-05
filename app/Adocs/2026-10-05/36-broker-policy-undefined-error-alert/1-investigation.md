# Investigation

| Checked | Evidence |
|---|---|
| 22 screenshots grouped by alert name | 1 Broker Policy alert, 7 Application Monitoring alerts |
| Application Monitoring names against seq 34 | All 7 are listed in seq 34 (URL, URL for MyAXA, function, AG Portal, BancaPotal, Compass, Compass PB) |
| Repeat searches | Same SPL as seq 34; Compass still has the extra メンテナンス中 rex |
| Broker alert in earlier answers | Not present in seq 27 to 35 |
| Broker search | `index=brokerpolicymaintenance-prod-axa-li-jp *Cannot read properties of undefined* \| timechart span=1m count \| where count > 50` |
| Broker schedule | Last 5 minutes, every minute, For each result, no throttle |
| Broker action | Email, Normal, subject `Splunk Alert: $name$` |
| Index naming | Looks like an OCP namespace, same pattern as compass-prod-axa-li-jp |
| Secrets | PagerDuty keys visible in screenshots; not copied |
