# Control-M Alerts Investigation

| Screenshot | Alert | Schedule | Window | Trigger and throttle | Recipients |
|---|---|---|---|---|---|
| 1 | CH:UL Email Job status | 0 13 * * 2-6 | Today | > 0, throttle JOB_CODE 6 min | noda, yasuda, one cut off |
| 2 | CHDE010MJob Status for MyAXA UL Email | 30 11 * * 1-6 | Last 1 day | > 0 | digital marketing squad, emma support |
| 3 | CHDR010MJob Status for MyAXA User Registration Batch | Every day 06:00 | Default | > 0 | Same lists, CC chen and a Teams channel |
| 4 | CTL-M アベンドアラートV2 | */1 | Last 5 min | > 0, throttle JOB_CODE 6 min | Not visible |
| 5 | CTL-M:アベンドアラート | */1 | Last 5 min | > 0, throttle $result.JOB_CODE$ | Not visible |
| 6 and 7 | CTL-M:ジョブ実行結果通知 | */1 | Last 5 min | > 0, throttle $result.JOB_CODE$ 10 min | yoshida, CC $result.Email$ |
| 8 and 9 | CTL-M:リラン確認 | */4 | Last 8 hours | > 0 | Not visible |
| 10 | Claim Job Over Run Alert | */5 | Last 24 hours | > 0, no throttle | claims incident list |
| 11 | Claims Status Service PDDW0100 Status | 15 8 * * * | Last 24 hours | > 0 | Not visible |

| Observation | Meaning |
|---|---|
| Two sourcetypes | controlm_activejobs (snapshots of job state) and controlm_alert (abend events) |
| Five CSV lookups | Need uploading as Grail lookup files |
| Overlapping windows everywhere | Splunk relied on throttles to avoid repeats |
| Teams channel email in screenshot 3 | Not copied |
