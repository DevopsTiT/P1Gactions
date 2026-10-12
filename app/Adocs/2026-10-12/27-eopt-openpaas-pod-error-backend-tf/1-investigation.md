# eopt OpenPaaS Pod Error Investigation

| What was checked | Finding |
|---|---|
| Alert | eopt - OpenPaaS Pod Error (Backend) |
| Search | `index="eopt-prod-axa-li-jp" \| rex timestamp and level \| eval level=upper(level) \| search level="ERROR"` |
| Schedule | Run every hour, at minute 0 |
| Trigger | Results greater than 0, once |
| Throttle | Off |
| Action | Email only, Normal. Recipients not copied. |
| Host field | 12 pod names: eoptsystemapi, eoptprocessapi, eoptfrontend |
| Source | S3 log forwarder paths |
| Line format | `2026-10-12T08:36:54.955Z DEBUG [ip: ...] \| reqId: ... \| /api/actuator/health \| GET` |
| Volume | 299,005 events in about 24 hours |
