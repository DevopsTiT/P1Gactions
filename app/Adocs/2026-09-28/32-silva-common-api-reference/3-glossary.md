# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Table API | The REST API that reads and writes any ServiceNow table | Used for almost everything |
| Aggregate API | The REST API for counts and group-by | Counts per environment or per service in one call |
| CMDB Instance API | The REST API for CIs that returns their relationships | Shows everything linked to one host |
| CMDB Meta API | The REST API that describes a CI class | Lists fields without guessing |
| Encoded query | The filter string used in `sysparm_query` | Copy it from the list view breadcrumb |
| Dot-walking | Reading a field through a reference, such as `parent.name` | Pulls columns from linked tables in one call |
| sys_id | The unique 32-character id of a record | The most reliable way to set reference fields |
| Display value | The readable name of a reference or choice | Makes output human-readable |
| sys_dictionary | The table that defines every field | Find exact field names |
| sys_choice | The table of dropdown values | Valid Environment labels |
| ACL | An access rule in ServiceNow | The reason for 403 responses or empty results |
| X-Total-Count | A response header with the total rows | Tells you how many pages to fetch |
