# Result

The APIGateway FAILURE panel counts the data model `APIGW1015_Failure_count` for the dashboard time token `searchByTimer`, and refreshes every minute.

```
| pivot APIGW1015_Failure_count RootObject count(RootObject) AS "Count of 1600951249.6968_7EF4ECD2-84C5-40F9-B50C-B2D3D93AB3B9" ROWSUMMARY 0 COLSUMMARY 0 SHOWOTHER 1
```

| Piece | What it means |
|---|---|
| `pivot` | Count a data model. |
| `APIGW1015_Failure_count` | Data model that defines the failure events. |
| `RootObject` | Object being counted. |
| `count(RootObject)` | One number for the time window. |
| `AS "Count of ..."` | Generated column name. |
| `ROWSUMMARY 0` | No total row. |
| `COLSUMMARY 0` | No total column. |
| `SHOWOTHER 1` | OTHER bucket is allowed. This search does not split, so the result is still one number. |

Apply saves the dialog. The red color is on the chart format. Clone the panel and change the data model name to make the next count box. Copy the SUCCESS model name from that panel’s own Edit Search.
