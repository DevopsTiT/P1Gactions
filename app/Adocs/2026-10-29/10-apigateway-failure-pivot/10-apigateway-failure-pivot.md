# API Gateway Failure Pivot

```
Edit Search on APIGateway FAILURE
  search starts with pivot
    data model → APIGW1015_Failure_count
    object → RootObject
    count(RootObject) → one number
  time → Shared Time Picker token searchByTimer
  refresh → every 1 minute
  progress bar → shown while the search runs
  red color → set on the chart, outside this dialog
  Apply → saves the panel
  want the same box for another count
    clone the panel
    change the title
    change the data model name in the pivot
```

| Key point | Detail |
|---|---|
| Dialog | Edit Search, classic Splunk dashboard. |
| Panel title | APIGateway FAILURE. |
| Search | A pivot that counts one data model. |
| Data model | `APIGW1015_Failure_count`. |
| Object counted | `RootObject`. |
| Time | Shared Time Picker, token `searchByTimer`. |
| Refresh | Every 1 minute. Indicator is a progress bar. |
| Result shape | One count, which the big number displays. |

## Summary

This dialog is the search behind the APIGateway FAILURE number. It does not scan a raw index in the panel. It counts objects in the data model `APIGW1015_Failure_count` for whatever time the dashboard time picker currently has. Apply saves it. The red color is a chart setting on the panel, not a field in this dialog.

## Investigation

| Source | Finding |
|---|---|
| Dialog title | Edit Search. |
| Title field | APIGateway FAILURE. |
| Search | `\| pivot APIGW1015_Failure_count RootObject count(RootObject) AS "Count of 1600951249.6968_7EF4ECD2-84C5-40F9-B50C-B2D3D93AB3B9" ROWSUMMARY 0 COLSUMMARY 0 SHOWOTHER 1` |
| Time Range | Shared Time Picker (`searchByTimer`). |
| Auto Refresh Delay | 1 minute. |
| Refresh Indicator | Progress bar. |
| Buttons | Cancel, Convert to Report, Apply. |
| Behind the dialog | APIGateway SUCCESS shows 20,049 in green. A neighboring panel shows 0. |

The long name after `AS` is the column name Splunk wrote when this pivot was created. The single-value chart displays the count.

## Result

Read the dialog from top to bottom.

**Title** is the label above the number: `APIGateway FAILURE`.

**Search String** is the whole query:

```
| pivot APIGW1015_Failure_count RootObject count(RootObject) AS "Count of 1600951249.6968_7EF4ECD2-84C5-40F9-B50C-B2D3D93AB3B9" ROWSUMMARY 0 COLSUMMARY 0 SHOWOTHER 1
```

| Piece | What it means |
|---|---|
| `pivot` | Count a data model for the selected time. |
| `APIGW1015_Failure_count` | The data model. The failure selection lives in that model. |
| `RootObject` | The object inside the model that gets counted. |
| `count(RootObject)` | How many objects fall in the time window. |
| `AS "Count of ..."` | The column name. The long id is the name Splunk generated. |
| `ROWSUMMARY 0` | No total row. |
| `COLSUMMARY 0` | No total column. |
| `SHOWOTHER 1` | Leftover groups may be labeled OTHER. This search has no split, so the result stays one number. |

There is no `SPLITROW` and no `SPLITCOL`. One row and one count is what a single-value panel needs.

Open **Settings → Data models** and select `APIGW1015_Failure_count` to see which events the model includes. The panel will follow that definition.

**Run Search** runs the pivot once so you can check the number before saving.

**Time Range** is `Shared Time Picker (searchByTimer)`. This panel has no private time. The dashboard input whose token is `searchByTimer` supplies Last 15 minutes, or whatever is selected on the page.

**Auto Refresh Delay** of 1 minute runs this search again every minute while the dashboard is open.

**Refresh Indicator** of Progress bar draws a bar on the panel while that search is running.

**Apply** writes the dialog onto the panel. **Cancel** leaves the saved panel as it was. **Convert to Report** saves the search as a report and points the panel at that report. The current panel works with Apply alone.

The green **20,049** behind the dialog is the APIGateway SUCCESS panel. The **0** beside it is a different panel. This dialog does not show the failure count. Close it, or use Run Search, to see the failure number for the current time.

### Make the next box the same way

1. Edit the dashboard.
2. Clone the APIGateway FAILURE panel, or add a Single value panel.
3. Open Edit Search.
4. Set the title, for example `APIGateway SUCCESS`.
5. Keep the same pivot shape. Change the data model name to the model that panel already uses. Open the SUCCESS panel’s Edit Search to copy that name.
6. Set Time Range to Shared Time Picker (`searchByTimer`).
7. Set Auto Refresh Delay to 1 minute.
8. Set Refresh Indicator to Progress bar.
9. Apply.
10. Open the chart format and set the number color. Green for a success panel. Red for a failure panel. That color stays on the panel when the count is 0.

To retitle the count column, change only the `AS` text, for example `AS failure_count`. Leave the data model name and `count(RootObject)` as they are.

## Data flow map

```
Dashboard time input
 token searchByTimer
 Last 15 minutes, or the range currently selected
        |
        v
APIGateway FAILURE panel
 every 1 minute
        |
        v
pivot data model APIGW1015_Failure_count
 object RootObject
        |
        v
count(RootObject) → one number
        |
        v
Single value chart
 title APIGateway FAILURE
 color set on the chart
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the dialog shows. |
| `2-result.md` | Field-by-field reading and how to clone it. |
| `3-glossary.md` | Terms. |
| `10-apigateway-failure-pivot-follow.txt` | Same steps for mobile. |
| `10.sh` | Copy commands. |

Commands: [10.sh](10.sh)
