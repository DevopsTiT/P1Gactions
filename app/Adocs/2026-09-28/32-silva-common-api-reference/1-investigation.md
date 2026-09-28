# Investigation

| What was checked | Finding |
|---|---|
| APIs already used in seq 18, 29, 30 and 31 | All of them use the Table API. The Aggregate API was only used for plain counts. |
| APIs used by the workflow YAMLs | Table API POST (create), GET by correlation_id (find), PATCH (update and resolve) |
| Close code in the CLOSE YAML | `Solved (Permanently)`, reused in line 30 |
| Useful APIs not yet used | Aggregate API group-by, CMDB Instance API (host plus relationships), CMDB Meta API, and sys_dictionary discovery |
| Custom field names | `u_environment` is a custom field. Verify it with line 2 before relying on it. |
| Commands run | None. Everything is in `32.sh`. |
