# Input To cmdb_ci Investigation

| Checked | Finding |
|---|---|
| entity_tags | No service or offering tag. Has host, support group, environment, legal entity, trigram, platform, OS. |
| dt.security_context | AGO_INFRA_OVERALL, AGO_OS_OVERALL_ACC, AGO_OS_WIN_ACC and others. No service name. |
| affected_entity_names | [INFRA.ACC] Windows System. |
| event.description | Mentions EPAS servers unreachable. |
| Group offering step in code | Matched only offering assignment_group by name. Now matches assignment_group or support_group, by sys_id when known. |
| Check | All five workflows parse and compile. |
