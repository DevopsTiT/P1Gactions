# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Business service | The SNOW service record the incident is about. | Here it is fixed to QA Platforms for testing. |
| Service offering | A sub-record of the business service, often per company. | Must match "QA Platforms - AXA GROUP OPERATIONS" exactly. |
| Fixed value | A value written in the settings block, the same for every ticket. | Easy to test with, but change it before go-live. |
| Display value | The label you see in the form, like "3 - Medium". | The workflow sends labels, and SNOW drops labels that do not match. |
| notFilled | List the POST task returns of fields SNOW left blank. | Tells you which label did not match. |
| correlation_id | Field that stores the Dynatrace problem ID. | CLOSE finds the ticket with it. |
