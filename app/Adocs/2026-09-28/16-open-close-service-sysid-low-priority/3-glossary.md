# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Reference field | A field that points to another record, like business service. | Safest to set with the record's sys_id. |
| sys_id | 32-character unique ID of a SNOW record. | Always matches exactly one record. |
| cmdb_ci_service | Table that holds business services. | Where the workflow looks up uk-sap-fscd-dev. |
| service_offering | Table that holds service offerings. | Where the workflow looks up the offering. |
| Default offering | Offering a SILVA rule fills in when none is valid. | The odd "- AXA GROUP OPERATIONS ... _2026-07-27" value. |
| Priority matrix | Rule that turns impact and urgency into priority. | Impact 4 and urgency 4 gave 4 - Low on your ticket. |
| serviceLookup / serviceFix | Parts of the task result. | Show what was found and what SNOW kept. |
