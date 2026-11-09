# Investigation

| Source | Finding |
|---|---|
| Dynatrace resource attributes | `dt.entity.host_group` is the entity id. Shape: `HOST_GROUP-` plus letters. |
| Same page | `dt.host_group.id` is the human-readable group name. |
| Community DQL | On a host record the id is `instance_of[dt.entity.host_group]`. |
| Seq 2 | Proposed scope `HOST_GROUP-9034BF4FC7D158B2` is the value to compare. |
