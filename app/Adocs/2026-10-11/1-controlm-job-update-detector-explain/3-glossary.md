# Control-M Job Update Detector Glossary

| Term | What it means | Why you care |
|---|---|---|
| Control-M | The scheduler that runs batch jobs. | The changes come from here. |
| Job definition | The saved setup of a job: command, calendar, conditions. | Editing it changes how the batch runs. |
| is_current_version | Y when the row is the live version. | Old versions are ignored. |
| Condition | A signal like L-JOBA-OK that a job waits for. | It tells us the job that runs before. |
| pre_job | The job that must end OK first. | Shows what feeds the changed job. |
| post_job | Jobs that wait for this one. | Shows what a change could break. |
| append | Splunk adds rows from a second search. | Replaced by a lookup in DQL. |
| lookup | DQL joins fields from a subquery on a key. | Brings post_job onto each job. |
| summarize | DQL grouping, like Splunk stats. | One row per job. |
| Identity fields | Fields that decide if two rows are the same problem. | Stops duplicates. |
| Records detector | Opens a problem for each row the query returns. | One row is one changed job. |
| Grail | Dynatrace's log storage. | Where the definition export lands. |
