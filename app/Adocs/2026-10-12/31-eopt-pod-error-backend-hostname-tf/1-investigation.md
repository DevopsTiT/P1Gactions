# eopt Pod Error Host Name Investigation

| What was checked | Finding |
|---|---|
| Splunk index | eopt-prod-axa-li-jp, 293,715 events in about 24 hours |
| Hosts | 12 pods: eoptsystemapi-564c45bd9f-*, eoptprocessapi-7d49b9558c-*, eoptfrontend-688699b58f-* |
| Alert | eopt - OpenPaaS Pod Error (Backend) |
| Search | rex timestamp and level, upper, level ERROR |
| Schedule | Every hour at minute 0 |
| Trigger | Results greater than 0 |
| Action | Email, Normal. Recipients not copied. |
| Assumption | Logs in Dynatrace with host.name = pod name |
