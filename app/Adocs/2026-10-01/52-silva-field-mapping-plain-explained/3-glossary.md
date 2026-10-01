# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Form box | One field on the SILVA incident form. | Each map line fills one. |
| Server record | Row in table `cmdb_ci` for a machine. | Source of Configuration item. |
| Service Offering | One service in one environment. | Required box. |
| Business service | The bigger service an offering belongs to. | Required box. |
| parent | Offering field naming its business service. | How box 3 is found. |
| Company | Owner company record. | Required box. |
| Assignment group | Team that owns the ticket. | Decides who works it. |
| Environment | Production, Pre-Production, and so on. | Also picks the offering. |
| Correlation ID | Our problem id stored on the ticket. | CLOSE finds the ticket by it. |
| sys_id | Unique id of a record. | What the boxes really store. |
| svc_ci_assoc | Server-to-service link list. | Way 1 to find the offering. |
| cmdb_rel_ci | Dependency link list. | Way 2. |
| Incident history | Past tickets on the same server. | Way 3; used for P-261090. |
