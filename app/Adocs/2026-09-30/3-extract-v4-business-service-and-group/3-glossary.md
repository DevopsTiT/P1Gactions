# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Assignment group | The SNOW team that owns the incident | A wrong or unknown group means nobody gets the ticket |
| Business service | The SNOW service record the incident belongs to | Drives impact, reporting and routing |
| Service offering | An environment-specific part of a business service | Lets SNOW tell Production from Test |
| CI | Configuration item: a host, DB or app record in the CMDB | SNOW can link the incident to it and derive the service |
| sys_id | The 32-character internal ID of any SNOW record | Sending the sys_id avoids name mistakes |
| sys_user_group | The SNOW table of groups | Used to check that a group really exists |
| svc_ci_assoc | The table that links CIs to services | One way to go from a host to its service |
| cmdb_rel_ci | The table of CI relationships | Another way to find the parent service |
| GROUP_MAP / SERVICE_MAP | Fixed answers you type into the workflow | Use them when a search picks the wrong record |
| ready_for_snow | True when SNOW has a valid group and a service or CI | A quick go / no-go check |
| Scope | A permission given to the workflow | Missing scopes make SDK calls fail |
