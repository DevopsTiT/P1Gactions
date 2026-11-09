# API Gateway Failure In Dynatrace

```
Edit Search titled APIGateway FAILURE
  pivot counts data model APIGW1015_Failure_count
    index eip1015
    sourcetype eip_mediator_serverlog
    Status=FAILURE
  time comes from the shared picker searchByTimer
  refresh every 1 minute
  the chart shows one number
Dynatrace
  logs for apigw5500/server.log must be ingested
  tile counts lines whose text contains Status: FAILURE
  dashboard time Last 15 minutes
  refresh every 1 minute
  single value, 1 and above red
```

| Key point | Detail |
|---|---|
| Panel | APIGateway FAILURE. |
| Splunk search | A pivot that counts one data model. |
| Data model | `APIGW1015_Failure_count`. |
| Real filter | `index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE`. |
| Clock | Shared Time Picker, token `searchByTimer`. On the helper page that is Last 15 minutes. |
| Refresh | Every 1 minute. |
| Dynatrace picture | One single-value tile named APIGateway FAILURE. |

## Summary

This dialog counts API Gateway failure events for the dashboard time range and refreshes that count every minute. The data model already selects `Status=FAILURE` from the mediator server log. In Dynatrace, build one DQL tile that counts log lines from `apigw5500/server.log` whose text contains `Status: FAILURE`, on a dashboard set to Last 15 minutes with a 1 minute refresh.

## Investigation

| Source | Finding |
|---|---|
| Dialog | Edit Search. Title `APIGateway FAILURE`. |
| Search | `pivot APIGW1015_Failure_count RootObject count(RootObject)`. |
| Column name | `Count of 1600951249.6968_7EF4ECD2-84C5-40F9-B50C-B2D3D93AB3B9`. That id is the dataset id. |
| Flags | `ROWSUMMARY 0`, `COLSUMMARY 0`, `SHOWOTHER 1`. No split, so one number. |
| Time Range | Shared Time Picker (`searchByTimer`). |
| Auto Refresh Delay | 1 minute. |
| Refresh Indicator | Progress bar. |
| Data model constraint | `index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE`. |
| Log file | `/opt/softwareag/log/1015/apigw5500/server.log`. |
| Status text in a log line | A visible event contains `Status: SUCCESS`, so the failure text is `Status: FAILURE`. |

## Result

### What the dialog does

| Setting | What it means |
|---|---|
| Title | The label above the number: `APIGateway FAILURE`. |
| `pivot` | Count a data model for the selected time. |
| `APIGW1015_Failure_count` | The data model. The failure selection lives inside it. |
| `RootObject` | The object being counted. |
| `count(RootObject)` | How many failure events fall in the time window. That is the big number. |
| `AS "Count of ..."` | The column name Splunk generated. The chart uses the number. |
| `ROWSUMMARY 0` | No total row. |
| `COLSUMMARY 0` | No total column. |
| `SHOWOTHER 1` | Leftover groups may be labeled OTHER. This search does not split, so the result stays one number. |
| Shared Time Picker | This panel uses the time selected on the dashboard. |
| 1 minute | The search runs again every minute while the dashboard is open. |
| Progress bar | A bar shows on the panel while the search runs. |
| Apply | Saves the dialog onto the panel. |

The red color is set on the chart, outside this dialog. Run Search checks the number before you save.

The model’s constraint is the search that decides which events are counted:

```
index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE
```

### Create the same tile in Dynatrace

Check the log first. In Notebooks, set the time picker to Last 15 minutes and run:

```
fetch logs
| filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
| limit 5
```

No rows means Dynatrace does not have this file yet. Add a log ingest rule for `/opt/softwareag/log/1015/apigw5500/server.log` on the mediator hosts, then run the check again.

Build the page:

1. Open Dashboards and create a dashboard.
2. Set the time picker to Last 15 minutes.
3. Set auto-refresh to 1 minute.
4. Add a DQL tile and paste the query below.
5. Choose Single value. Bind it to `failure_count`.
6. Title the tile `APIGateway FAILURE`.
7. Set the color so 1 and above is red. Leave 0 a calm color.
8. Save.

```
data record(failure_count = 0)
| append [
    fetch logs
    | filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
    | filter contains(content, "Status: FAILURE", caseSensitive:false)
    | summarize failure_count = count()
  ]
| summarize failure_count = sum(failure_count)
```

Leave `from:` off `fetch logs`. The tile then follows the dashboard time picker, the same job as `searchByTimer`. The first line plants a 0, so an empty window still shows a number. If the number ignores the picker, add `from: now()-15m` on the inner `fetch logs`.

## Data flow map

```
server.log
 /opt/softwareag/log/1015/apigw5500/server.log
        |
        v
Splunk index eip1015
 sourcetype eip_mediator_serverlog
 Status=FAILURE
        |
        v
pivot count
 shared time picker
 refresh 1 minute
        |
        v
APIGateway FAILURE
 one red number

Same count in Dynatrace
 log.source contains apigw5500/server.log
 content contains Status: FAILURE
        |
        v
single value failure_count
 Last 15 minutes
 refresh 1 minute
 1 and above = red
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the dialog and the data model show. |
| `2-result.md` | The dialog reading and the DQL. |
| `3-glossary.md` | Terms. |
| `19-apigateway-failure-in-dynatrace-follow.txt` | Same steps for mobile. |
| `19.sh` | Copy commands. |

Commands: [19.sh](19.sh)
