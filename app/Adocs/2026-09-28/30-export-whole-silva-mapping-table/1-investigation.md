# Investigation

| What was checked | Finding |
|---|---|
| Seq 18 export commands | They export each table separately (groups, services, offerings), so there is no host column and no join. |
| Seq 29 lookup commands | They look up one host at a time, not the whole table. |
| Where the host-to-service link lives | `svc_ci_assoc` (ci_id → service_id). `cmdb_rel_ci` is the fallback in some instances. |
| Can one export show both sides? | Yes. The Table API and list views support dot-walked fields such as `ci_id.name` and `service_id.support_group`. |
| Why offerings need a second export | One business service can have many offerings (one per environment), so they cannot be a single column. |
| Size limits | The Table API is paged with `sysparm_limit` and `sysparm_offset`. The `X-Total-Count` header gives the total. List exports have an instance row limit. |
| Commands run | None. Everything is in `30.sh` for the user to run. |
