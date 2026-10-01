# Glossary

| Term | What it means | Why you care |
|---|---|---|
| cmdb_ci_service | Business services (and their child classes) | Main table searched |
| cmdb_ci_service_technical | Technical services, a child class of services | Your query.sh searched it separately |
| assignment_group.nameLIKE | Filter on the name of the linked group (dot-walk plus contains) | Finds services owned by the tag group |
| nameLIKE A ^ nameLIKE B | The name contains A and also contains B | DB type plus environment search |
| fqdn | Fully qualified domain name, for example `wndsql11.axa-id.intraxa` | Hosts are often stored with the domain |
| Search terms | The values taken from the tags for the searches | Shown in `lookup.search_terms` |
| Score | Points for how well a service matches the tags | Decides which service is picked |
| MIN_SCORE | Minimum points needed to pick a service | Prevents weak guesses |
| service_candidates | Top 10 services with scores | Lets you choose when the workflow cannot |
