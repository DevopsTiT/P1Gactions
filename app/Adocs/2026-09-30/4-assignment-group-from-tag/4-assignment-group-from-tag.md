# Assignment Group From Tag

## Decision tree

```
entity_tags has a group tag?
 ├─ yes → group name = tag value (Database_AXAJP)
 │     ├─ found active in SILVA? → add sys_id, verified_in_silva true
 │     └─ not found or call failed? → keep the tag name, verified_in_silva false
 └─ no → business service group → CI support group → default group
```

## Short takeaway

| Question | Answer |
|---|---|
| Which group does the input show? | Database_AXAJP |
| Which tags say so? | AGO_ORACLE_ASSIGNMENT_GROUP and AGO_DEFAULT_ASSIGNMENT_GROUP |
| Does the tag decide now? | Yes. The tag value always wins. |
| What is the SILVA check for? | Only to add the sys_id |
| What if the check fails? | The name is still sent. SNOW matches it by display name. |

## Summary

The tags are the source of truth for the group. Before this change, a failed SILVA check could drop the tag group and fall back to another group. Now the tag group is always kept, and `verified_in_silva` shows whether the sys_id was found.

## Change in the v4 workflow

| Place | Before | After |
|---|---|---|
| Group check fails in SILVA | Falls back to the service, CI or default group | Keeps the tag name, with `verified_in_silva: false` |
| `snow_required.assignment_group` | name, sys_id, from | Adds `verified_in_silva` |
| `ready_for_snow` rule | Needed a group sys_id | Needs a group name (from the tag or SILVA) |

## Expected output for this input

```json
"assignment_group": {
  "name": "Database_AXAJP",
  "sys_id": "5223d8c61b8f3c54688064e4604bcb12",
  "from": "tag AGO_ORACLE_ASSIGNMENT_GROUP",
  "verified_in_silva": true
}
```

## Data flow

```
entity_tags
   │ AGO_ORACLE_ASSIGNMENT_GROUP:Database_AXAJP
   ▼
extract-event-tags → group_candidates [Database_AXAJP]
   ▼
resolve-snow-values → sys_user_group lookup (adds sys_id only)
   ▼
snow_required.assignment_group = Database_AXAJP
```

## Related files

| File | What it is |
|---|---|
| `../3-extract-v4-business-service-and-group/3-extract-v4-business-service-and-group.workflow.yaml` | Updated workflow |
| `4.sh` | Group check command |

## Commands

See `4.sh`.
