# Result

| Step | Do this |
|---|---|
| 1 | Run `check.dql` query 1 to see the memory parse bug |
| 2 | Delete alert 6 (duplicate of 7) |
| 3 | Replace the blocks with the `for_each` detector map (8 detectors) |
| 4 | Add the 3 email workflows |
| 5 | Ask the team about the 60-second throttle and the renames |
| 6 | `terraform validate` and `plan` (expect 8 detectors and 3 workflows) |
