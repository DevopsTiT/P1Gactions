# AG Portal NTTGW NG Investigation

| What I checked | What I found |
|---|---|
| Source | index jenkins, source jenkins/test, host ceaa2099.prprivmgmt.intraxa. |
| Excluded results | ABORTED and FAILURE. |
| Pairing | Real Time Check renamed to its Functional project. |
| Application | "AG Portal NTTGW" from the configuration lookup. |
| Last runs | streamstats keeps the last 2 runs per job. |
| Trigger | event=2 or recovery (OK after NG). |
| Action | Alert Status Manager, Production, PagerDuty Enable. |
| Schedule | cron */30, Last 30 minutes. |
