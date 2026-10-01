# Investigation

| What was checked | Finding |
|---|---|
| Standard OPEN flow (seq 36) | Layout, settings style, sample-event handling and sync keys reused. |
| Earlier CLOSE v2 (2026-09-28 seq 3) | PATCH logic, close notes idea and "did not move to Resolved" check reused. |
| close_code value | Never confirmed in SILVA. Workflow reads the sys_choice list and the preview flags WRONG. |
| Validation | YAML parses. All 7 scripts pass `node --check`. Positions and predecessors match the standard layout. |

No SILVA or PagerDuty calls were run by the agent.
