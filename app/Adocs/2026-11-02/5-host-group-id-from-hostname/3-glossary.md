# Glossary

| Term | What it means |
|---|---|
| Host group id | The Dynatrace entity id. It starts with `HOST_GROUP-`. Terraform `scope` uses this. |
| Host group name | The label people read on the host page. |
| `instance_of[dt.entity.host_group]` | The host record’s link to its host group entity. |
| `entityName(...)` | Turns that link into the group name. |
| Host id | The machine’s own id. It starts with `HOST-`. |
