# Result

| Step | What to do |
|---|---|
| 1 | Allowlist silvastg.service-now.com and events.pagerduty.com |
| 2 | Add scope environment-api:problems:read |
| 3 | Upload `9-v6-full-open-silva-pagerduty.workflow.yaml` |
| 4 | Set DRY_RUN = true in tasks 4 and 5, press Run, check each task result |
| 5 | Set DRY_RUN = false and activate the trigger |
| 6 | Deactivate older OPEN workflows so tickets are not created twice |
| 7 | Keep the CLOSE workflow active |
