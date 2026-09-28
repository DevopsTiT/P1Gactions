# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Environment (u_environment) | Custom SILVA choice field for the environment. | Now always Production. |
| Business service | The SNOW service record the incident belongs to. | Now always QA Platforms. |
| Service offering | A specific offer under the business service, here per company, environment and product. | Must be sent as its full Name. |
| Record Name | The full text stored on the offering record. | The form field may show only the start of it. |
| sys_id | Unique ID of a SNOW record. | A safe fallback when a Name does not match. |
| Fixed value | A setting that wins over tags. | Keeps the environment and the offering consistent. |
