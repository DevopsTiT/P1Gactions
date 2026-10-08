# Investigation

| What was checked | Finding |
|---|---|
| Search | `index=brokerpolicymaintenance-prod-axa-li-jp *Cannot read properties of undefined* \| timechart span=1m count \| where count > 50` |
| Schedule | Every minute, Last 5 minutes |
| Trigger | Results > 0, Once, no throttle |
| Action | Email to one person and the infra list, priority Normal |
| Hosts | 2 pods, `broker-policy-maintenance-web-5649696b64-*` |
| Log format | JSON with level, message, spanId, timestamp, traceId |
| Log path | S3 log forwarder |
