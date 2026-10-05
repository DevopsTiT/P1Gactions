# Glossary

| Term | What it means |
|---|---|
| Terraform state | Terraform's record of which real objects it created; one per working folder or backend |
| Stack | One folder of Terraform files applied together with one state |
| Duplicate resource | Error when two blocks in one folder have the same type and name |
| `terraform state mv` | Moves an object's record from one address or state to another without recreating it |
| `terraform import` | Adopts an existing real object into state |
| for_each | Creates one object per map entry from a single block |
| Detector | Dynatrace Davis anomaly detector that opens a problem when a query crosses a rule |
| Workflow | Dynatrace automation that runs on a schedule or event, for example to send email |
| Grail lookup | A table file uploaded under `/lookups/` and joined in DQL |
