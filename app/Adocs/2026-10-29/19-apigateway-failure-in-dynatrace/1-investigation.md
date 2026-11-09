# Investigation

| Source | Finding |
|---|---|
| Title | APIGateway FAILURE. |
| Search | Pivot on `APIGW1015_Failure_count`, object `RootObject`, `count(RootObject)`. |
| Time | Shared Time Picker (`searchByTimer`). |
| Refresh | 1 minute, progress bar. |
| Constraint | `index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE`. |
| Log file | `/opt/softwareag/log/1015/apigw5500/server.log`. |
| Status text | A sample line shows `Status: SUCCESS`. The failure match is `Status: FAILURE`. |
