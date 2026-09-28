# Glossary

| Term | What it means | Why you care |
|---|---|---|
| CUSTOM_ALERT | Dynatrace severity for alerts from custom rules, such as log queries | Maps to the lowest impact. |
| Root cause entity | The entity Dynatrace marks as the cause | isRootCause is "true" only when it exists. |
| Affected entity | An entity impacted by the problem | Used as correlation_id when there is no root cause. |
| dt.event.title | Short title of the event | Shown as "title" in the JSON. |
| dt.event.description | Detailed description of the event | Used as the ticket headline. |
