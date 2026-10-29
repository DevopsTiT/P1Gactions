# Glossary

| Term | What it means |
|---|---|
| Edit Search | The classic dashboard dialog that stores one panel’s title, search, time, and refresh. |
| Pivot | A Splunk search that counts or splits a data model. |
| Data model | A saved definition of which events belong together. This panel uses `APIGW1015_Failure_count`. |
| RootObject | The object inside that data model. The pivot counts it. |
| `count(RootObject)` | The number of those objects in the selected time. |
| `AS` | Renames the count column. |
| `ROWSUMMARY 0` | Do not add a total row. |
| `COLSUMMARY 0` | Do not add a total column. |
| `SHOWOTHER 1` | Allow an OTHER group when a pivot splits values. |
| Shared Time Picker | The dashboard time input. This panel’s token is `searchByTimer`. |
| Auto Refresh Delay | How often the panel search runs again. Here, 1 minute. |
| Progress bar | The mark drawn on the panel while the search is running. |
| Apply | Saves this dialog onto the panel. |
| Single value | The chart that turns the one count into the big number. |
