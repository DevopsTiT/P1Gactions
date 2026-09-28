# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Classic integration | Dynatrace's built-in ServiceNow notification | INC30339531 came from it; it is the model to copy. |
| AGO tags | AXA tags on Dynatrace entities, like AGO_AXA_SUPPORTGROUP | They carry the SILVA group and environment. |
| Root-cause event | The Davis event marked as the cause of the problem | Holds the detailed description and properties. |
| event_properties | Key/value details of the event (threshold, metric, timeout) | Copied into the Summary JSON. |
| Entities API | Dynatrace API returning entity details and relationships | Gives the host name and IP addresses. |
| Derive from CI | SILVA filling business service from the CI's CMDB links | Why the example has a business service without sending one. |
| svc_ci_assoc | SILVA table linking CIs to services | Backup when SILVA does not derive. |
