# Glossary

| Term | What it means |
|---|---|
| Terraform state | Terraform's record of which real objects it created |
| Duplicate resource | Error when two blocks in one folder share type and name |
| `terraform state mv` | Moves an object's record to a new address or state without recreating it |
| `terraform import` | Adopts an existing real object into state |
| for_each | Creates one object per map entry from one block |
| Sensitive variable | A Terraform input hidden from plan output; passed via `TF_VAR_<name>` |
| Placeholder | Text like `{dims:application}` that Dynatrace fills in when it creates a problem |
| arrayMovingMax | DQL function: for each point, the max of the last N points |
| Sparse series | A timeseries where many minutes have no data |
| violatingSamples | How many bad minutes in the window open a problem |
| Log event rule | `dynatrace_log_events`: turns matching log lines into events |
