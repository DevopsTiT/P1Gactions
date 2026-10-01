# Default Assignment Group Tag

## Decision tree

```
Which assignment group does the workflow use?
  GROUP_MAP has the app code?                 → yes: use the mapped group
  AGO_AXA_SUPPORTGROUP tag exists?            → yes: use it
  specific *_ASSIGNMENT_GROUP tag exists?     → yes: use it (here AGO_ORACLE_ASSIGNMENT_GROUP = Database_AXAJP)
  AGO_DEFAULT_ASSIGNMENT_GROUP tag exists?    → yes: use it (here also Database_AXAJP, removed as a duplicate)
  no tag at all?                              → business service group → CI support group → DEFAULT_GROUP
  tag group name not found in SILVA?          → try the next tag; if none match, keep the name without a sys_id
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the user's reading right? | Yes. AGO_DEFAULT_ASSIGNMENT_GROUP is Database_AXAJP. |
| Which tag did the workflow actually use? | AGO_ORACLE_ASSIGNMENT_GROUP, which is also Database_AXAJP. |
| Is the result different? | No. Both tags give the same group, sys_id 5223d8c61b8f3c54688064e4604bcb12. |
| Why does the Oracle tag win? | The workflow prefers the more specific tag. The default tag is only a fallback. |
| What to verify in SILVA? | That the group named exactly Database_AXAJP exists and is active (21.sh line 2). |

## Summary

The event has two group tags with the same value. The workflow tries the specific Oracle tag first and the default tag last. Because the values are the same, the default tag is dropped as a duplicate, and the final group is Database_AXAJP either way.

## Tags on this event

| Tag key | Value | Priority in the workflow | Used? |
|---|---|---|---|
| AGO_ORACLE_ASSIGNMENT_GROUP | Database_AXAJP | Second (specific group tag) | Yes |
| AGO_DEFAULT_ASSIGNMENT_GROUP | Database_AXAJP | Third (fallback) | No. Same value, so it is skipped. |

## When the two tags would matter

| Situation | What happens |
|---|---|
| Both tags have the same value (this event) | Same group, no difference. |
| The Oracle tag has a group that does not exist in SILVA | The workflow tries the default tag next and uses it if that group exists. |
| Only the default tag exists | The default tag group is used. |
| The tags have different, valid groups | The Oracle tag wins. If the team wants the default tag to win, change the order in task 1. |

## Name must be exact

The SILVA lookup is `sys_user_group` with `name=<tag value>^active=true`. The real SILVA name is `Database_AXAJP` with an underscore. A value like `Database-axa-jp` with hyphens would not match and would fall through to the next source.

## Data flow

```
entity tags
  → task 1: group_candidates [AGO_ORACLE_ASSIGNMENT_GROUP=Database_AXAJP]  (default tag deduped)
  → task 2: sys_user_group name=Database_AXAJP → sys_id 5223d8c6…cb12
  → GROUP_ORDER: tag wins
  → task 3: assignment_group = 5223d8c6…cb12
```

## Related files

| File | Purpose |
|---|---|
| `22.sh` | Query to confirm the group in SILVA. |
| `21-silva-verify-checklist/` | Full SILVA verify list. |
| `18-preview-v7-no-post/18-preview-v7-no-post.workflow.yaml` | Task 1 group_candidates order and task 2 GROUP_ORDER. |

## Commands

See `22.sh`.
