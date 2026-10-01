# Glossary

| Term | What it means |
|---|---|
| sys_id | The 32-character unique ID of any record in ServiceNow. |
| Reference field | A field that stores another record's sys_id, such as assignment_group. |
| sys_choice | The table that lists allowed values for choice fields like impact. |
| Business rule | Server-side logic in ServiceNow that can change fields when a record is saved. |
| Assignment rule | A rule that sets or changes assignment_group automatically. |
| correlation_id | Our Dynatrace problem ID stored on the incident to prevent duplicates. |
| sysparm_display_value=all | Returns both the stored value and the readable name for each field. |
| Read back | Fetching the record after creating it to confirm what was really saved. |
