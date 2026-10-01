# Investigation

| What was checked | Finding |
|---|---|
| Screenshot trigger panel | Event state "active or closed", categories Error, Custom, Resource, Slowdown, Availability. |
| Canvas title | "...to SILVA and PagerDuty v1" (seq 39), Draft. |
| YAML onProblemClose: true | Shown in the UI as "active or closed". |
| v1 to v3 close tasks | No status check, so an open event could resolve tickets. |
| v4 | is_closed from Problems API status, else event status or transition. YAML parses, scripts pass `node --check`. |
