# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Trigger event | The JSON Dynatrace hands to the workflow when a problem opens or changes | It is the raw material. SILVA never sees it directly. |
| entity_tags | Labels attached to the affected Dynatrace entity | This is where application, environment and owner hints live. |
| dt.cost.product | Tag naming the product for cost reporting | It is a stable application name, good as a mapping key. |
| env tag | Tag naming the environment (TST, STG, PRD) | It decides the SILVA environment and offering. |
| Pod | One running copy of a container in Kubernetes | Pods are replaced often, so their names are useless for the CMDB. |
| CMDB | SILVA's database of systems (servers, services) | SILVA uses it to fill the business service from a CI. |
| CI (cmdb_ci) | A single item in the CMDB, such as a server | If we send an unknown CI, SILVA cannot derive anything. |
| Business service | The application as SILVA knows it (cmdb_ci_service) | It is required for correct reporting and routing. |
| Service offering | An environment-specific variant of a business service | It must match the environment. |
| support_group | The group that supports a business service in SILVA | It is the best source for the assignment group. |
| Mapping table | A small lookup in the YAML from Dynatrace tag to SILVA names | It turns Dynatrace language into SILVA language. |
