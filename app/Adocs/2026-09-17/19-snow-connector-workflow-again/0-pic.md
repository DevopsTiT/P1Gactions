# Pic — ServiceNow Connector Workflow

```
Problem open?
  yes → prepare-payload
         ├─ snow-create-incident (Connection)
         └─ PagerDuty trigger (parallel)
         then snow-comment-on-incident
  close → search by correlation_id
         → snow-resolve-incident
         → PagerDuty resolve
```

```
Connector path (this pack)
  Workflow snow-* actions + Connection
  Classic ITSM OFF

Not this pack
  Classic Problem notification as INC creator
  JS fetch to SNOW REST
```
