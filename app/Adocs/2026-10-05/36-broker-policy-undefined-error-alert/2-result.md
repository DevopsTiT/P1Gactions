# Result

| Item | Outcome |
|---|---|
| New Terraform | 1 detector: `Prod_BrokerPolicyMaintenance_UndefinedPropertyError_Normal` |
| Seq 34 detectors | No change |
| Workflow | Not needed |

## Next Steps

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 to confirm logs are found by `k8s.namespace.name` |
| 2 | Run queries 2 and 3 to see how often the threshold would have fired |
| 3 | Confirm recipients with the owner (one named person plus the infra list) |
| 4 | `terraform plan` shows 1 to add |
| 5 | Run in parallel with Splunk, then disable the Splunk alert |
