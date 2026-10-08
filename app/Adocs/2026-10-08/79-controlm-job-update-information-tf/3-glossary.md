# Control-M Job Update Information Glossary

| Term | What it means | Why you care |
|---|---|---|
| Job definition | The saved setup of a Control-M job: command, calendar, conditions. | A change here changes how production batches run. |
| def_ver_jobs | Control-M export of job definition versions. | Main data source. |
| def_ver_lnki_p | A second Control-M definition export (another table). | Same fields, also included. |
| is_current_version | Y when the row is the live version of the definition. | Old versions are ignored. |
| condition | A Control-M in-condition such as L-JOBA-OK. | It names the job that must finish first. |
| pre_job | The job that must end OK before this one runs. | Shows what feeds the changed job. |
| post_job | Jobs that wait for this job. | Shows what a change could break downstream. |
| append | Splunk adds the rows of a second search under the first. | In DQL this is a lookup. |
| lookup | DQL joins fields from a subquery on a key. | Brings post_job onto each job. |
| Identity fields | Fields that decide when two rows are the same problem. | Stops the same change opening twice. |
