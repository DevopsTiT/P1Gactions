# Result

| Step | Do |
|---|---|
| 1 | Import `17-open-v7-silva-pagerduty.workflow.yaml` |
| 2 | Set `DRY_RUN = true` in tasks 4 and 5 for the first real problem |
| 3 | Check task 3 output: decision ok, payload keys right |
| 4 | Set DRY_RUN back to false |
| 5 | Turn off TEST v7 and OPEN v6 triggers |
| 6 | After the first real incident, run `17.sh` line 1 to check the fields in SILVA |
