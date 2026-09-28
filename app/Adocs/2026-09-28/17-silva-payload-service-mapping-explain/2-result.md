# Result

| Finding | Action |
|---|---|
| Business service was blank because SILVA could not match the CI | Send a host name SILVA knows, or send the business service directly by sys_id. |
| The team wants system name, business service and L1/L2 group in the payload | Read them from Dynatrace tags per entity. |
| No-match case must go to a default | Add a default SILVA business service and group as a fallback. |
| Service-level problems have no host | Look up the host through Dynatrace relationships. |
| UPDATED events trigger OPEN | Remove UPDATED or check for an existing INC first. |

Next: agree tag names and defaults with Abhay and Davesh, then update the YAMLs (tags first, defaults as fallback).
