# Glossary

| Term | What it means | Why you care |
|---|---|---|
| SILVA | AXA's name for their ServiceNow instance. | Same as ServiceNow in the chat. |
| CMDB | Configuration Management Database: SNOW's list of systems (CIs). | SILVA maps a CI to its business service and group. |
| CI (configuration item) | One system in the CMDB, such as a host. | The "system name" Abhay mentions. |
| Metadata | Extra details sent with an alert, like the host name. | What the classic integration passed and ours lacked. |
| Service-level problem | A Dynatrace problem on a service, not a host. | The event has no host name. |
| Relationships | Dynatrace links between entities, such as service runs on host. | How to find the host for a service problem. |
| Tag | A key:value label on a Dynatrace entity. | Where to store the SILVA business service and groups. |
| Default business service | Fallback when no match is found. | Abhay's no-match rule. |
| status_transition UPDATED | The problem changed but was not newly created. | Can cause duplicate tickets if OPEN fires on it. |
