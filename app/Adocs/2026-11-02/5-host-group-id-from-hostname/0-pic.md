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
