# How To Build Pic

```
1 Dynatrace event + Problems API ─► which keys exist (display_id, tags, entities)
2 Known-good INC ─────────────────► which fields a ticket needs
3 sys_dictionary / XML ───────────► real keys (u_business_service, cmdb_ci, u_configuration_item)
4 GET tables (display_value=all) ─► sys_ids
5 svc_ci_assoc, cmdb_rel_ci, service_offering, incident history ─► how CI → service → offering
6 sys_choice ─────────────────────► allowed values (state, close_code)
7 PagerDuty test trigger/resolve ─► routing key works
8 Build: extract → resolve → build → preview → send
9 Test: sample, DRY_RUN, previews
10 Live: allowlist, Deploy, one OPEN + one CLOSE
```
