# Glossary

| Term | What it means |
|---|---|
| Data model | A saved definition of which events belong in a pivot. |
| Constraint | The search that decides which events enter the model. |
| RootObject | The object name inside `APIGW1015_Failure_count`. The pivot counts it. |
| Dataset id | The long id Splunk assigned to that object. The pivot column is “Count of” that id. |
| index=eip1015 | The Splunk index for this EIP log set. |
| sourcetype | The kind of log. Here, `eip_mediator_serverlog`. |
| Status=FAILURE | Keeps failure rows. The open search does not include this filter. |
| Paused search | The job stopped before you read a finished total. Resume it to let it finish. |
| source | The log file path on the event. |
| host | The machine that wrote the event. |
