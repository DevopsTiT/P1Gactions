# Result

| Step | What to do |
|---|---|
| 1 | Run 31.sh line 3 (only `fscd`) and check that `u_environment` and `parent.used_for` are filled. |
| 2 | If a field is empty, check its real name in SILVA (right-click the label, then Show field name) and update line 2. |
| 3 | Run line 2 to export all offerings. |
| 4 | Run line 4 to get `silva_env_pairs_long.csv` and `silva_env_pairs_wide.csv`. |
| 5 | Check the wide table. A cell marked `(+n more)` means that environment has several services, so pick the right one by hand. |
| 6 | Copy the pairs you need into `SYSTEM_MAP` per environment (suggested structure in the main md). |
