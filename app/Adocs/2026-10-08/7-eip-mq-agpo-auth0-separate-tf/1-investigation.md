# Investigation

| What was checked | Finding |
|---|---|
| Seq 6 structure | One resource `eip_agpo_alerts` with `for_each` over 2 keys |
| Folder loading | Terraform loads every tf file in the folder as one configuration |
| Provider | Declared once in a shared file to avoid duplicate errors |
| Queries | Unchanged from seq 6 |
