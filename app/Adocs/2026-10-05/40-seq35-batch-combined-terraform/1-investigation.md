# Investigation

| Checked | Evidence |
|---|---|
| Seq 35 screenshots | 4 alerts; 3 repeat seq 34 |
| Seq 36 screenshots | 8 alerts; 7 repeat seq 34 |
| Unique alerts across seq 34, 35, 36 | 12 |
| File 1 resources | `jenkins_app_monitoring` (2 via for_each), `jenkins_aggw_lb_response_outlier` |
| File 2 resources | File 1 plus `broker_policy_undefined_error` |
| Same-folder clash | Both files define `jenkins_app_monitoring`, so they live in separate subfolders |
| Seq 35 fixes | Placeholder removed and arrayMovingMax added in both files |
