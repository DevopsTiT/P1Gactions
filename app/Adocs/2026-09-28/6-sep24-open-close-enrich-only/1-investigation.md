# Investigation

| What was checked | Finding |
|---|---|
| Requirement note (pic 1) | Business service EIP, Category, Impact, Assignment group L1 L2 L3, customer notes with cause, link, service, dashboard, application EIP and Dynatrace link. |
| INC30339599 (pic 2) | Environment, Business service, Category, Subcategory and Assignment group are blank. Impact, Urgency and Priority show "3 - Medium". External Ticket Number P-260915195 is filled, so the correlation_id sync works. |
| Sep 24 OPEN body | Sent only short_description, description, correlation_id, impact, urgency, caller_id, u_host and work_notes. That explains the blanks. |
| Sep 24 CLOSE PATCH | Sent state, close_code and a one-line close_notes. |
| Scope | Enrich only. No new tasks, no trigger changes, no CMDB lookup, no extra verification step. |

No commands were run.
