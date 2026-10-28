# Glossary

| Term | What it means | Why you care on this slide |
|---|---|---|
| Gate 0 | Early request form that defines the problem before a build. | Pic 1 is only the business-requirements page. |
| Business Value Chain | The business area that owns the work. | You tick boxes. You do not write a paragraph here. |
| Use case | One process, told from start to finish. | The form wants use case 1 and use case 2 when the work splits. |
| Before AI | The process as it runs today. | Both use cases stay in that time. |
| Dynatrace | Monitoring tool that raises a problem. | It is the detector. Keep it. |
| PagerDuty | Incident tool that pages the on-call person and stores acknowledge, escalate, and resolve. | It is the system of record. Keep it. |
| PagerDuty AI (Advance) | Paid assist that can answer in Microsoft Teams after an incident exists. | It is the future state. Leave it out of the “current process” box. |
| Microsoft Teams | Chat where the PagerDuty app posts the incident and people talk. | This is the chat channel on the slide. |
| Primary | The on-call SRE who is paged first. | Actor in use case 1. |
| Secondary | The backup on-call person. | Actor in use case 2 when they join late. |
| System of record | The tool that officially holds the incident state. | That tool is PagerDuty. |
| Handoff | Giving the incident to the next person with enough context to continue. | Use case 2. Today this is manual reading. |
| Post-incident note | The write-up after resolve. | Today it is written from memory and chat. |
| Toil | Repeated manual work that does not fix the service. | Catch-up and status writing are the toil on this page. |
