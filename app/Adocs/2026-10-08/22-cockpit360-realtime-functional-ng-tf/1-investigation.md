# Cockpit360 NG Investigation

| What I checked | What I found |
|---|---|
| Index | jenkins_statistics, sourcetype json:jenkins:old. |
| Jobs | applications* (Functional) and group-jobs* (Real Time). |
| Name pairing | tempname from "Building ..." with " » " turned into "/". |
| Application | Cockpit360. |
| Schedule | cron */1, Last 2 hours. |
| Final search | event > 0 or recovery. |
| Action | Alert Status Manager, Production; PagerDuty not visible. |
| Host | ceaa2099.prprivmgmt.intraxa (screenshot 3). |
