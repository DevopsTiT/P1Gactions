# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Filter navigator | Search box at the top left of SILVA | Typing `<table>.list` opens any table. |
| CI | Configuration item, e.g. a server record | The workflow sends the host as CI. |
| cmdb_ci_server | SILVA table of servers | Where hosts like ts12 live. |
| svc_ci_assoc | Links CIs to services | Tells which business service a host belongs to. |
| Related list | Linked records shown at the bottom of a form | Quick way to see a host's services. |
| Table API | SILVA REST API `/api/now/v2/table/<table>` | Scriptable lookups. |
| ACL | SILVA access rule | Can hide records from the API user. |
