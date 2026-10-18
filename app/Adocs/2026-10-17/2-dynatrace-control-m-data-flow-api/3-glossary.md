# Control-M Data Flow Glossary

| Term | What it means |
|---|---|
| Path A | Log ingest into Grail, then DQL detectors |
| Path B | ActiveGate extension calling Automation API |
| Path C | OneAgent on Control-M JVMs |
| Automation API | Control-M HTTPS API under `/automation-api` |
| Run service | API group for job run and status |
| `GET /run/jobs/status` | Search many job statuses |
| `GET /run/job/{jobId}/status` | One job run status |
| Grail | Dynatrace log (and more) storage |
| ActiveGate | Runs remote extensions such as Jobs v2 |
| `controlm.job.status` | Extension metric for one job's state |
| Davis problem | Dynatrace incident from detector or event |
