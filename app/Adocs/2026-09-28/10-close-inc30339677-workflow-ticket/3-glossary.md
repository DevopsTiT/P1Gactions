# Glossary

| Term | What it means | Why you care |
|---|---|---|
| correlation_id | SNOW field that stores the Dynatrace problem display ID. | The CLOSE workflow finds the INC with it. |
| display_id | Short problem ID like P-260915247. | This is what the workflow stores as correlation_id. |
| problem_id | Long internal problem ID. | The Dynatrace Problems API needs it to close a problem. |
| dedup_key | PagerDuty key that links trigger and resolve events. | The value `dt-problem-P-260915247` resolves the matching PagerDuty incident. |
| Resolved (state 6) | SNOW "work done" state. | The CLOSE workflow sets this. |
| Closed (state 7) | Final SNOW state, set by the auto-close timer. | You wait for it rather than set it. |
| problems.write | Dynatrace token scope. | Needed to close a problem by API. |
