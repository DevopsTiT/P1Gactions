# Result

| Item | Outcome |
|---|---|
| Combined file | `38-all-alerts-combined-terraform.tf`, supersedes seq 37 |
| Seq 35 fix 1 | Placeholder removed from event.description |
| Seq 35 fix 2 | `arrayMovingMax(responsetime, 10)` added after makeTimeseries |
| Original seq folders | Unchanged |

## Next Steps

| Step | What to do |
|---|---|
| 1 | Choose state strategy (new stack or per-seq folders) |
| 2 | Export the two PagerDuty TF_VAR values from a secret store |
| 3 | Upload Control-M and Jenkins lookups |
| 4 | Resolve the 24 CONFIRM lines |
| 5 | `terraform plan`, then apply and compare with the old alerts |
