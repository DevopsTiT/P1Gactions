# Glossary

| Term | What it means | Why you care |
|---|---|---|
| sys_id | SILVA's unique id for a record | Reference fields are only reliable when set by sys_id. |
| Reference field | A field pointing to another record (business service, CI) | An unmatched name is dropped silently. |
| FQDN | Full host name with domain, like zdahka204b.pprivmgmt.intraxa | CMDB often stores only the short name. |
| CI | Configuration item, a CMDB record such as a server | With a CI, SILVA can find the business service itself. |
| svc_ci_assoc | SILVA table linking CIs to services | Used to read the host's business service. |
| Child class | A more specific table under cmdb_ci_service | One name can appear in several classes. |
| ACL | Access rule in SILVA | Can hide records from the API user. |
| Field changes | Audit entry in the INC activity | Shows which fields were set, and when. |
