# Result

```
fetch dt.entity.host
| filter contains(entity.name, "CEAA20F7", caseSensitive:false)
| fieldsAdd host_group_id = instance_of[dt.entity.host_group]
| fieldsAdd host_group_name = entityName(instance_of[dt.entity.host_group])
| fields entity.name, id, host_group_id, host_group_name
```

Copy `host_group_id` into Terraform `scope`.

| Result | Meaning |
|---|---|
| `HOST_GROUP-9034BF4FC7D158B2` | The note matches this host. |
| A different `HOST_GROUP-` id | Use the id from this row. |
| Empty | This host has no host group. |
