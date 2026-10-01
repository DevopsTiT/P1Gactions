# Investigation

| What was checked | Evidence |
|---|---|
| sys_documentation labelLIKEConfiguration | incident and task: element u_configuration_item |
| sys_dictionary reference=cmdb_ci | cmdb_ci, u_application, u_configuration_item, u_business_process |
| Incident fields containing ts12 | u_configuration_item display ts12.hk.intraxa, link cmdb_ci/1dfdcf8adb8dfa40251af9971d961941 |
| cmdb_ci cfbf255f... | sys_class_name Service Offering |
| service_offering parent=37273dbc... | 1 row, Non-Operational, no u_environment returned |
| First jq error | `[200~curl: command not found` = bracketed paste artifact |
