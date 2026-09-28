# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Enrichment | Adding context (service, cause, links) to an alert before it becomes a ticket. | Saves the on-call engineer from searching. |
| Business service | The SNOW record for the service the business sees, here EIP. | Drives reporting and SLA. |
| Assignment group L1 | First-line team that triages. | Default owner of new tickets. |
| Assignment group L2 | Application support team. | Gets production outages directly. |
| Assignment group L3 | Engineering or vendor team. | Escalation for code or platform fixes. |
| `comments` | SNOW Additional comments (customer visible). | Where the notes block goes. |
| `work_notes` | SNOW internal notes. | Still used for the sync keys. |
| `sysparm_input_display_value=true` | Lets you send labels and names instead of codes and sys_ids. | A label that does not match is dropped with no error. |
| `notFilled` | List in the OPEN task result of fields SILVA left empty. | Tells you which label to fix. |
| `sys_choice` | SNOW table holding dropdown labels and values. | Source of the correct category and impact labels. |
| Problems API | Dynatrace API returning tags, root cause and evidence for a problem. | Source of the cause and tags. |
| `dedup_key` | PagerDuty key tying trigger and resolve together. | Unchanged sync key. |
