# Result

| Step | Action |
|---|---|
| 1 | `39.sh` line 1: confirm CLOSE_CODE. |
| 2 | Import `39-close-direct-silva-pagerduty.workflow.yaml`, Run (skips, shows would_resolve). |
| 3 | ALLOW_SAMPLE_POST true in both close tasks, Run to really close P-261090. |
| 4 | `39.sh` line 2: confirm Resolved. |
| 5 | ALLOW_SAMPLE_POST false, Save / Deploy. Keep only one CLOSE workflow active. |
