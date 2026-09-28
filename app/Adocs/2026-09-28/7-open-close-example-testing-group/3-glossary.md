# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Classic integration | The older built-in Dynatrace to ServiceNow problem notification. | Created the example ticket; its values are known to work in SILVA. |
| `TEST_ASSIGNMENT_GROUP` | A setting that forces every ticket to one group. | Keeps test tickets away from real support teams. |
| `AGO_AXA_SUPPORTGROUP` tag | Dynatrace tag holding the owning support group name. | Normal routing source after testing. |
| `AGO_AXAENVIRONMENTNAME` tag | Dynatrace tag holding the environment label. | Source of the Environment field. |
| Configuration item (`cmdb_ci`) | The CMDB record for the affected server. | Links the ticket to the host. |
| Service offering | A specific level of a business service (for example Silver). | Mandatory on the SILVA form. |
| Contact type | How the ticket was raised (Phone, Email, Event). | "Event" marks it as monitoring-generated. |
| `notFilled` | Fields SILVA left empty after the POST. | Shows which label to fix. |
| correlation_id | Field used to find the same ticket at close. | Must stay the problem ID. |
