# Dynatrace Control-M Glossary

| Term | What it means |
|---|---|
| Control-M | BMC job scheduler for batch workflows. |
| Control-M/EM | Enterprise Manager control plane. |
| Agent | Host process that starts OS jobs and writes daily logs. |
| `daily_ctmag_*.log` | Agent daily log with STARTED and ENDED lines. |
| ORDERID | Id for one ordered run. |
| RUNNO | Run number within that order. |
| Ended Not OK | Failed / abend end state. |
| Overrun | Job still running longer than the allowed time. |
| AJF | Active Job File. |
| Automation API | Control-M HTTP API used by the Hub extension. |
| Control-M Jobs v2 | Dynatrace Hub extension for job status metrics. |
| ActiveGate | Dynatrace gateway that runs the remote extension. |
| CTM-13123 | BMC issue: OneAgent 1.327 crashes EM on Linux. |
