# Broker Policy Maintenance Investigation

| What I checked | What I found |
|---|---|
| Search | `stats dc(host) as host` on the broker-policy-maintenance index. |
| Trigger | Custom, `search host < 2`. |
| Window and cron | Last 60 minutes, hourly. |
| Action | Email, Priority Normal. |
| Host values | Two web pods, about 55% and 45% of events. |
| Source | S3 log forwarder bucket. |
