# Investigation

| What was checked | Finding |
|---|---|
| Activities on INC30341416 | Field change at 16:27:10: Incident State Resolved was New, Resolved by Dynatrace JP, Resolver Group set. |
| In Progress entry | None, so the direct attempt worked. |
| Close Notes entries | 16:17 (v1) and 16:27 (v2): sent twice. |
| Work note block | Only 16:17: v2 did not repeat it. |
| Form | Incident State Resolved, Assigned to empty, External Ticket Number P-261090. |
| v2 success check | Compared only `state`; could misreport if `state` does not follow incident_state. |
| v3 validation | YAML parses. All 3 scripts pass `node --check`. v2 file unchanged. |
