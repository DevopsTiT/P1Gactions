# Investigation

| What was checked | Finding |
|---|---|
| Seq 24 OPEN | Used event tags only as a fallback when the Problems API returned none; fixed values beat metadata. |
| COMPASSPROXY event | Has entity_tags, dt.security.context, affected_entity_types SERVICE, no host. |
| zdahka204b INC | Host problem; no SILVA service or group tag seen. |
| SILVA Environment | Mandatory field; only Production and Development confirmed so far. |
