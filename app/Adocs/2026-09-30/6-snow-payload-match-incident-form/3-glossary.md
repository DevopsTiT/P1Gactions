# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Mandatory field | A form field marked with a star | SNOW rejects or blocks the ticket without it |
| Choice field | A drop-down field like Impact or Category | The API needs the stored value, not the label you see |
| Reference field | A field that points to another record, like Caller or Company | Send a sys_id, or a name SNOW can match |
| sysparm_display_value=all | API option that returns both the value and the label | Shows what to send for each field |
| Service offering | Environment part of a business service | Mandatory on this form |
| correlation_id | Hidden field holding the Dynatrace problem id | CLOSE uses it to find the ticket |
| snow_form_check | New output block, one row per form field | Shows at a glance what is missing |
