# Investigation

| What I checked | What I found |
|---|---|
| OPEN source | `36-standard-flow-preview-then-post.workflow.yaml`, 1,248 lines, 7 tasks. |
| CLOSE source | `45-close-direct-v5-trigger-closed.workflow.yaml`, 426 lines, 3 tasks. |
| SILVA sync key | OPEN line 848 sets `correlation_id` to the display id; CLOSE line 274 searches by it. |
| PagerDuty sync key | OPEN line 884 and CLOSE line 139 both build `dt-problem-<display id>`. |
| Stale comment | CLOSE line 126 still says the trigger fires on "active or closed". Code is unaffected. |
| Possibly confusing text | OPEN line 814 writes the entity id as "correlation_id:" inside the description text. The real field is line 848. |
| Gate difference | OPEN 5a checks preview `problems`; 5b checks preview `ready`. |
