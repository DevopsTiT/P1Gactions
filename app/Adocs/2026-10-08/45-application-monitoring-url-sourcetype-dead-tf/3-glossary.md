# URL Sourcetype Glossary

| Term | What it means | Why you care |
|---|---|---|
| sourcetype | Splunk label for the log format | A wrong value makes the search match nothing |
| Dead alert | An alert whose search can never return results | It hides real failures |
| enabled = false | Terraform creates the detector switched off | Lets you check before it starts alerting |
| Scheduler log | Splunk `_internal` record of each alert run | Shows result_count, which proves the alert returns 0 |
