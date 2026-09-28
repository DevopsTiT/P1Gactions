# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Table API | ServiceNow REST API for reading or writing table rows. | GET requests only read, so they are safe. |
| sys_user_group | Table of groups, including assignment groups. | Source of the L1 and L2 group names. |
| cmdb_ci_service | Table of business services. | Source of the business service names. |
| service_offering | Table of offerings under a business service. | Source of the offering per environment. |
| svc_ci_assoc | Service mapping links between a service and its CIs. | Shows which service a host belongs to. |
| cmdb_rel_ci | General relationships between CIs. | Another way to find a host's service. |
| Filter navigator | Search box at the top left of the SILVA UI. | Type `<table>.list` to open any table. |
| sysparm_limit / sysparm_offset | Page size and start row for API results. | Needed for big tables. |
| jq | Command-line JSON tool. | Turns API output into CSV. |
| ACL | Access control rule in SNOW. | Can hide tables or rows from the API user. |
