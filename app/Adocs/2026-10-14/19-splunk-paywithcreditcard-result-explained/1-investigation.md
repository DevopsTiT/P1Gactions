# Splunk PayWithCreditCard Result Investigation

| What was checked | Finding |
|---|---|
| Search text | `message.url=*payWithCreditCard_Adj*` uses wildcards. |
| Result count | 75 events in 1 hour. |
| `url` value | Full URL ending in `/payWithCreditCard_Adj`. |
| `level` | info. |
| `target_system` | PC_CUSTOMER. |
| `host` | Pod name `portals-amp-backend-5f57cbc7-...`. Two pods. |
| `source` | `s3://axa-gi-jp-logforwarders-prod/...`. One S3 file per event. |
| JSON `timestamp` | UTC. Splunk Time column shows JST. |
| Impact on earlier DQL | `msg_url ==` would return 0 rows. Needs `contains()`. |
