# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Retired field | A field kept in the table but no longer used (label "ZZZ-Do-not-use") | Values sent there are never seen |
| Relabelled field | A standard field shown with a new label | `cmdb_ci` shows as "Service Offering" in SILVA |
| u_business_service | SILVA custom reference to cmdb_ci_service | Where the business service goes |
| Service offering | Child of a business service, per environment and tier | Goes in `cmdb_ci` |
| HOST_CI_FIELD | New workflow setting | Key for the host CI once confirmed |
