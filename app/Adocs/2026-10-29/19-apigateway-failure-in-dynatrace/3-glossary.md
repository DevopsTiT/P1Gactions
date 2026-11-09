# Glossary

| Term | What it means |
|---|---|
| Pivot | A Splunk search that counts a data model. |
| Data model | A saved filter. This one keeps failure rows from the mediator log. |
| `RootObject` | The object inside `APIGW1015_Failure_count`. |
| `count(RootObject)` | How many of those events are in the time window. |
| Shared Time Picker | The dashboard clock. Token `searchByTimer`. |
| Auto Refresh Delay | How often the panel runs again. Here, 1 minute. |
| Tile | One box on a Dynatrace dashboard. |
| `failure_count` | The Dynatrace number that matches the Splunk count. |
| Single value | The picture that shows that one number. |
