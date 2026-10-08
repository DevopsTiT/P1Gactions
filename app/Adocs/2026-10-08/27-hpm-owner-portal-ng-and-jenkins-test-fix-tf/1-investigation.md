# HPM Owner Portal NG Investigation

| What I checked | What I found |
|---|---|
| HPM alert | jenkins/test template, application HPM_Owner_Portal, Last 2 hours, PagerDuty Enable. |
| Raw jenkins/test events | Plain applications/* jobs with event_tag build_report. |
| Splunk logic | Keeps all jobs; only App-Ops Functional results are emptied. |
| Seq 19, 20, 23 | Filtered on App-Ops-OpenOps only; missed plain jobs. |
