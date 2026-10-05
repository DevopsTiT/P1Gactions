# Result

| Step | Do this |
|---|---|
| 1 | Remove the integration key from the file; rotate it in PagerDuty if it was pushed |
| 2 | Ask the BRE team what the cron should be (hours 1 to 5, weekdays, or always) |
| 3 | Run `parse-check.dql` to confirm the parse matches real lines |
| 4 | Apply the detector and PagerDuty workflow from `main.tf`, passing the key as a sensitive variable |
| 5 | Rename the alert to `Prod_Life_BRE_InnoRulesError` |
| 6 | `terraform validate` and `plan` |
