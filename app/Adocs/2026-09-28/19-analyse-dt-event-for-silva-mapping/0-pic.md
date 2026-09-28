# Event To SILVA Mapping Picture

```
Run workflow event JSON
 not sent to SILVA as-is -> it is the input to prepare-payload
 has snow-service tag? no
 app key: dt.cost.product:COMPASSPROXY (backup: app, dt.security.context)
 env key: env:TST -> Test
 host tag = pod names -> ignore for CMDB
 search SILVA "compass"
   business service -> cmdb_ci_service
   offering         -> service_offering (Test/Dev)
   group            -> support_group of that business service
 put results in SERVICE_MAP -> fallback to current defaults
```

```
event -> prepare-payload (map tags) -> POST incident -> sys_id PATCH -> ticket filled
```
