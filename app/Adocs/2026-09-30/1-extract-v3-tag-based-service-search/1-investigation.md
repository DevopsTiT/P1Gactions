# Investigation

| What was checked | Finding |
|---|---|
| query.sh line 47 | Technical services: `cmdb_ci_service_technical nameLIKE Infrastructure` |
| query.sh line 52 | Business services: `cmdb_ci_service nameLIKE Infrastructure` |
| query.sh line 57 | Host: `cmdb_ci name=WNDSQL11 ^OR fqdn=WNDSQL11.axa-id.intraxa`, with fields `service` and `business_service` |
| query.sh line 62 | Search 1: `cmdb_ci_service assignment_group.nameLIKE Database_AXAJP` |
| query.sh line 66 | Search 2: DB type plus environment in the service name (Oracle, Acceptance) |
| query.sh line 70 | Search 3: DB type plus region in the service name (Oracle, AP-SOUTHEAST) |
| Mapping to the tags | Group, DB type, environment and region all come from the Oracle alert's AGO_ tags |
| v2 gap | v2 did not search services by group, DB type, environment or region, and did not use fqdn with a domain |
| Commands run | None |
