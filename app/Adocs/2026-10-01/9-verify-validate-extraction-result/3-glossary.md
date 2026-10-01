# Glossary

| Term | What it means | Why you care |
|---|---|---|
| sys_id | 32-character unique ID of a ServiceNow record | Reference fields need this, not a name |
| Reference field | A field that points to another record (caller_id, assignment_group) | A name is ignored unless input_display_value is used |
| Table extension | A child table inherits a parent table | Querying cmdb_ci_service also returns service_offering rows |
| sys_class_name | The real table of a record | Used to exclude offerings |
| sys_choice | Table of allowed values for choice fields | Empty result means no read access |
| Reference incident | A known-good incident used for comparison | Only constant fields should match across apps |
