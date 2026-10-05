# Result

| Item | Outcome |
|---|---|
| Combined file | `37-splunk-migration-combined-terraform.tf` |
| Contents | 14 detectors and 7 workflows from 39 Splunk alerts |
| Resource changes | None versus the seq files |

## Next Steps

| Step | What to do |
|---|---|
| 1 | Decide: new single stack, or keep the per-seq folders (never both against the same tenant without moving state) |
| 2 | Upload lookup files for Control-M and Jenkins |
| 3 | Fix every CONFIRM line |
| 4 | `terraform plan` shows 21 to add |
| 5 | Apply, compare with Splunk for a few days, then disable Splunk alerts |
