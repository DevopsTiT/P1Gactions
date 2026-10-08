# CCI Goal Management Glossary

| Term | What it means | Why you care |
|---|---|---|
| source | Splunk's field for where an event came from | Here it is always "jenkins/test", so it can't be a job name |
| build_report | A Jenkins event sent after each build | Has job_name and job_result, but no HTTP status |
| job_result | The Jenkins build outcome (SUCCESS, UNSTABLE, FAILURE, ABORTED) | The signal the rebuilt detector uses |
| Stuck alert | An alert whose result never changes | It gives no real signal |
| Alert Status Manager | A Splunk action that mails on status change | Explains why a stuck NG mails once and then goes quiet |
