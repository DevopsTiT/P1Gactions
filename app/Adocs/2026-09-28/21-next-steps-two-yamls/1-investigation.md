# Investigation

| What was checked | Finding |
|---|---|
| Seq 20 OPEN settings | SYSTEM_MAP has EIP with blank group and offering; COMPASSPROXY is commented out. |
| Placeholders | `__L3_GROUP__`, `__EIP_DASHBOARD_URL__`, `__PD_SERVICE_URL__` remain. |
| OPEN trigger | It includes UPDATED, so duplicate incidents are possible. |
| CI handling | `ciName` falls back to the service name for service-level problems, which SILVA cannot match. |
| Test-only values | FIXED_ENVIRONMENT, FIXED_IMPACT, FIXED_URGENCY and ASSIGNED_TO are set for testing. |
| CLOSE | Needs only the same map keys and URLs. |
