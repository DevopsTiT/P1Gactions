# Investigation

| Source | Finding |
|---|---|
| Splunk model | `APIGW1015_Failure_count`. |
| Constraint | `index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE`. |
| Status text in a log line | `Status: SUCCESS` was visible, so the failure match is `Status: FAILURE`. |
| Log path | `/opt/softwareag/log/1015/apigw5500/server.log`. |
| Hosts | `WPLALJ2BF`, `WPLALJ2CB`, `WPLALJ2BC`, `WPLALJ2BB` in `prprivngt.intraxa`. |
| Panel clock | Last 15 minutes, refresh every 1 minute. |

The wider Splunk search without `Status=FAILURE` is the one that showed 259,387. The Dynatrace failure tile keeps the failure filter.
