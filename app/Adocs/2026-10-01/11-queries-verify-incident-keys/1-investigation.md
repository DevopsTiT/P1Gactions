# Investigation

| What was checked | Evidence |
|---|---|
| Keys to verify | 18 guessed `u_` keys plus description and opened_at from seq 10 |
| Where labels live | `sys_documentation` (label per language) |
| Where fields live | `sys_dictionary` (element, type, reference, read_only, mandatory) |
| Parent table | incident extends task, so both names are queried |
| Access risk | The workflow got 0 rows from sys_choice, so system tables may be blocked; V3 is the fallback |
| Table API behavior | Unknown keys in `sysparm_fields` are dropped from the response |
