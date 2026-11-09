# API Gateway Success Pivot

```
Edit Search titled APIGateway SUCCESS
  same shape as APIGateway FAILURE
  data model → APIGW1015_Success_count
  count(RootObject) → one number
  time → shared picker searchByTimer
  refresh → every 1 minute
  green color → set on the chart
  confirm the model constraint
    failure model uses Status=FAILURE
    this model name is Success_count
    open the model before treating the filter as Status=SUCCESS
```

| Key point | Detail |
|---|---|
| Panel | APIGateway SUCCESS. |
| Search | A pivot that counts one data model. |
| Data model | `APIGW1015_Success_count`. |
| Number | `count(RootObject)` for the dashboard time. |
| Clock | Shared Time Picker, token `searchByTimer`. |
| Refresh | Every 1 minute, with a progress bar. |

## Summary

This dialog is the success count next to APIGateway FAILURE. It counts objects in the data model `APIGW1015_Success_count` for whatever time the dashboard picker has, and it runs again every minute. The green color is on the chart, not in this dialog.

## Investigation

| Source | Finding |
|---|---|
| Title | APIGateway SUCCESS. |
| Search | `pivot APIGW1015_Success_count RootObject count(RootObject)`. |
| Column label | A short name ending in `Success`. The failure panel used a long dataset id instead. |
| Flags | `ROWSUMMARY 0`, `COLSUMMARY 0`, `SHOWOTHER 1`. No split. |
| Time Range | Shared Time Picker (`searchByTimer`). |
| Auto Refresh Delay | 1 minute. |
| Refresh Indicator | Progress bar. |
| Failure model, already opened | `index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE`. |
| Sample log line | Contained `Status: SUCCESS`. |

This success model’s constraint box was not opened on this screen.

## Result

| Setting | What it means |
|---|---|
| Title | The label above the green number. |
| `pivot` | Count a data model for the selected time. |
| `APIGW1015_Success_count` | The data model for the success count. |
| `RootObject` | The object being counted. |
| `count(RootObject)` | How many of those events are in the time window. |
| `AS "Count of ...Success"` | The column name. The chart uses the number. |
| `ROWSUMMARY 0` | No total row. |
| `COLSUMMARY 0` | No total column. |
| `SHOWOTHER 1` | This search does not split, so the result stays one number. |
| Shared Time Picker | Same clock as the failure panel. |
| 1 minute | The search runs again every minute. |
| Progress bar | Shown while the search runs. |
| Apply | Saves the dialog onto the panel. |

Open **Settings → Data models → APIGW1015_Success_count** to read the constraint. The failure model on the same gateway log is `Status=FAILURE`. This model’s name is the success count, and a sample line contains `Status: SUCCESS`.

The matching Dynatrace tile uses that success text:

```
data record(success_count = 0)
| append [
    fetch logs
    | filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
    | filter contains(content, "Status: SUCCESS", caseSensitive:false)
    | summarize success_count = count()
  ]
| summarize success_count = sum(success_count)
```

Single value on `success_count`. Title `APIGateway SUCCESS`. Color it green. Same dashboard clock and 1 minute refresh as the failure tile.

## Data flow map

```
mediator server log
        |
        +--> data model APIGW1015_Failure_count
        |      Status=FAILURE
        |      red number
        |
        +--> data model APIGW1015_Success_count
               count(RootObject)
               shared time picker
               refresh 1 minute
               green number
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the dialog shows. |
| `2-result.md` | Field reading and the success DQL. |
| `3-glossary.md` | Terms. |
| `20-apigateway-success-pivot-follow.txt` | Same explanation for mobile. |
| `20.sh` | Copy commands. |

Commands: [20.sh](20.sh)
