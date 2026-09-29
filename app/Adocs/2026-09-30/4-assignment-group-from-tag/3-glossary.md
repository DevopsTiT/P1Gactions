# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Assignment group | The SNOW team that gets the incident | It must match a real SNOW group |
| Group tag | A Dynatrace tag like AGO_ORACLE_ASSIGNMENT_GROUP | The owner team is already written on the entity |
| sys_id | SNOW internal record ID | Sending it avoids name typos |
| verified_in_silva | True when SILVA returned the group's sys_id | Tells you whether SILVA confirmed the tag |
| Display name match | SNOW accepts a name in a reference field and finds the record | Lets the tag name work even without a sys_id |
