# Investigation

| Source | Finding |
|---|---|
| Window title | PC Queue Health. |
| Query | timeseries average of guidewire.messaging.status, app == "pc", split by queue id and name. |
| Result | 16 records. Timeframe 09:28:00–11:29:00 on 10/29/2026. |
| Chart title on the left | BC Failed Messages. The line is flat at 0. |
