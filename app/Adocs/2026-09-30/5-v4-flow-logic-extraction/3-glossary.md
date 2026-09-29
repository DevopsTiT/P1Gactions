# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Trigger event | The Dynatrace problem record that starts the workflow | All extraction starts from it |
| entity_tags | List of "KEY:value" tags on the affected entity | Main source for group, environment, DB, trigram |
| Candidate | A possible answer before it is checked | The first checked candidate wins |
| CI | Configuration item in the SNOW CMDB, such as a host or DB | Can link to its business service |
| svc_ci_assoc | SNOW table linking CIs to services | Path B4 |
| cmdb_rel_ci | SNOW relationship table | Path B5 |
| Score | Points given to a search result | Picks the most likely service |
| Offering | Environment-specific part of a service | Matches Production or Test |
| Preview | A body that is built but not sent | Safe testing |
