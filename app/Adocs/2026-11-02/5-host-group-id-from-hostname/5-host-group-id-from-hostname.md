# Host Group Id From Host Name

```
Need the HOST_GROUP- id for a hostname
  Notebook
    fetch dt.entity.host
    filter entity.name contains the hostname
    host_group_id = instance_of[dt.entity.host_group]
    empty id → this host has no host group
    id matches the note → this is the Terraform scope
    id is a different HOST_GROUP- value → the snippet is aimed at another group
  same answer on the host page
    search the hostname
    Properties → Host group
    click the group
    read the HOST_GROUP- id on that page
```

| What you read | Example shape | Where it goes |
|---|---|---|
| Host group id | `HOST_GROUP-9034BF4FC7D158B2` | Terraform `scope`. |
| Host group name | A short name people gave the group | The Hosts filter. |
| Host id | `HOST-` plus letters | The host itself. Leave this out of `scope`. |

## Summary

Search the hostname in a Notebook with `fetch dt.entity.host`. The field `instance_of[dt.entity.host_group]` is the host group id. That is the value Terraform puts in `scope`. The name shown on the host page is a label. Copy the id that starts with `HOST_GROUP-`.

## Investigation

| Source | What it settles |
|---|---|
| Dynatrace resource attributes | `dt.entity.host_group` is the entity id, shaped like `HOST_GROUP-008786529C8EE446`. |
| Same page | `dt.host_group.id` is the human-readable group name. |
| Dynatrace Community | On `dt.entity.host`, that entity id is `instance_of[dt.entity.host_group]`. |
| Seq 2 note | The proposed scope is `HOST_GROUP-9034BF4FC7D158B2`. This query is how you check CEAA20F7 against that value. |

## Result

### Notebook

Open a Notebook. Set the time picker to Last 2 hours. Paste this and replace the hostname if you are looking up a different machine.

```
fetch dt.entity.host
| filter contains(entity.name, "CEAA20F7", caseSensitive:false)
| fieldsAdd host_group_id = instance_of[dt.entity.host_group]
| fieldsAdd host_group_name = entityName(instance_of[dt.entity.host_group])
| fields entity.name, id, host_group_id, host_group_name
```

| Column | What to copy |
|---|---|
| `entity.name` | Check this is the host you meant. A short name can match more than one row. |
| `id` | The host id. It starts with `HOST-`. |
| `host_group_id` | The host group id. It starts with `HOST_GROUP-`. This is `scope`. |
| `host_group_name` | The label. Use it when you filter the Hosts list. |

| Row you get | Decision |
|---|---|
| `host_group_id` is `HOST_GROUP-9034BF4FC7D158B2` | The note’s scope is this host’s group. |
| `host_group_id` is a different `HOST_GROUP-` value | The snippet is aimed at another group. Use the id from this row. |
| `host_group_id` is empty | This host has no host group. There is no group id to put in `scope`. |
| Several rows | The name matched more than one host. Read `entity.name` and keep the full name you wanted. |

This query reads the host record. It still works when that host has sent no logs.

### Host page

Use this when you want to see the same id on screen.

1. Use the top search and type the hostname, for example `CEAA20F7`.
2. Open the host result.
3. Open Properties and find Host group.
4. Click that group name.
5. Read the id that starts with `HOST_GROUP-`. It is on the group page and in the page address.

The line on the host page shows the group name. The id appears after you open the group.

## Data flow map

```
hostname CEAA20F7
        |
        v
dt.entity.host
  entity.name contains the hostname
        |
        v
instance_of[dt.entity.host_group]
        |
        +--> HOST_GROUP-...     Terraform scope
        |
        +--> entityName(...)    name you see on the host page
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | How the hostname becomes the id. |
| `1-investigation.md` | Which field is the id. |
| `2-result.md` | The query and what each column means. |
| `3-glossary.md` | Terms. |
| `5-host-group-id-from-hostname-follow.txt` | The same steps for a phone. |
| `5.sh` | Copy commands. |

Commands: [5.sh](5.sh)
