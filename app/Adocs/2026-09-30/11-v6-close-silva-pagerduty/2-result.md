# Result

| Step | What to do |
|---|---|
| 1 | Run the sys_choice GET in `11.sh`, confirm state 6 and the close_code value |
| 2 | Upload `11-v6-close-silva-pagerduty.workflow.yaml` |
| 3 | Test: DRY_RUN true, ALLOW_SAMPLE_SEND true, press Run |
| 4 | Real: DRY_RUN false, ALLOW_SAMPLE_SEND false, activate |
| 5 | Deactivate the old CLOSE workflow |
| 6 | Keep OPEN v6 and CLOSE v6 both active |
