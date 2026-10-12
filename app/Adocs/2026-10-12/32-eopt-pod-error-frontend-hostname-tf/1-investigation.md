# eopt Pod Error Frontend Investigation

| What was checked | Finding |
|---|---|
| Alert | eopt - OpenPaaS Pod Error (Frontend) |
| Search | `index="eopt-prod-axa-li-jp" \| spath \| eval level=upper(level) \| search level="ERROR"` |
| Schedule | Every hour at minute 0 |
| Trigger | Results greater than 0, once |
| Throttle | Off |
| Action | Email, Normal. Recipients not copied. |
| Frontend hosts | eoptfrontend-688699b58f-* |
| Assumption | Logs in Dynatrace with host.name = pod name |
