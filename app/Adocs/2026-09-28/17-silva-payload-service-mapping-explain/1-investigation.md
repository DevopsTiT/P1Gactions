# Investigation

| What was checked | What it showed |
|---|---|
| Teams chat, Davesh | The classic integration sends the host name. SILVA maps the host to business service and group. |
| Teams chat, Abhay | The payload needs system name, business service and L1/L2 group, with a default business service when there is no match. |
| Event `affected_entity_types` | dt.entity.service, so it is a service-level problem. |
| Event `affected_entity_names` | [COMPASSPROXY.TST] compass-proxy-ccifa-* and similar. These are Dynatrace names, not SILVA CIs. |
| Event host field | No host.name. |
| Event `event.status_transition` | UPDATED. The OPEN trigger includes UPDATED. |
| Seq 16 OPEN code | `ciName = hostName || root.name`, so the service name was sent as cmdb_ci. |
| Seq 16 OPEN code | Fixed business service wins over tags. |
