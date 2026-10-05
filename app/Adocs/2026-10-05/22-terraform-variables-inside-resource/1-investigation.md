# Investigation

| What was checked | Finding |
|---|---|
| Question | Can the `variable` and `locals` blocks from seq 21 go inside the resources? |
| Terraform rules | `variable`, `locals`, `output`, `provider` are top-level only |
| References | `var.x` and `local.x` can be used anywhere, including heredocs |
| Module scope | All `.tf` files in one folder share names, so duplicates fail |
| Team style | One literal resource block per alert file |
