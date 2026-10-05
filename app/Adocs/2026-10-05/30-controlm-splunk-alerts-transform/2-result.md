# Control-M Alerts Result

| Resource | Type | Replaces |
|---|---|---|
| `controlm_daily_report` (4 entries) | Scheduled workflow, for_each | CH:UL Email Job status, CHDE010M MyAXA UL, CHDR010M User Registration, PDDW0100 |
| `controlm_job_abend` | Detector, per job_name | アベンドアラート V1 and V2 |
| `controlm_job_result_notify` | Workflow every 5 min, loop | ジョブ実行結果通知 |
| `controlm_rerun_check` | Workflow every 4 min | リラン確認 |
| `claims_job_overrun` | Workflow every 5 min | Claim Job Over Run Alert |

| Open decision | Options |
|---|---|
| Abends paging | Keep the detector (pages through the standard flow) or change to an email workflow |
| リラン確認 | Keep, or drop because ジョブ実行結果通知 already reports recoveries |
| CHDE010M two reports | Keep both schedules, or merge into one |
