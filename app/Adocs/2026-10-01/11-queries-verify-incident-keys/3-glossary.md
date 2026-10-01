# Glossary

| Term | What it means | Why you care |
|---|---|---|
| sys_documentation | Table of field labels per language | Label to key lookup |
| sys_dictionary | Table of field definitions | Proves a key exists and shows its type |
| element | The field key | What the payload uses |
| internal_type | Field data type | Tells you to send a sys_id, a choice value, or text |
| `IN` operator | Matches any value in a comma list | Check many keys in one call |
| `LIKE` operator | Contains text | Find a key when the guess is wrong |
| sysparm_fields | Which keys the API returns | Unknown keys are dropped, which is a free existence test |
