# Glossary

| Term | What it means | Why you care |
|---|---|---|
| servicenow_enrichment | The business service record's own fields (group, company, number) read from SILVA | The payload group and company now come from here |
| GROUP_ORDER | The list of sources tried for the assignment group, first hit wins | Controls tag vs enrichment vs default |
| Default set | QA Platforms values used when no service and no group tag are found | Now keeps the real environment |
| Reference field | A field that stores a sys_id pointing to another record (caller_id, company, assignment_group) | Must receive a sys_id, not a name |
| `sysparm_input_display_value=true` | Table API option that lets you send names to reference fields | Alternative to sys_ids |
| sys_choice | Table holding valid drop-down values per field | Task 4 checks environment, category, impact, urgency |
| Service offering | Child of a business service, usually one per environment | Must match the problem's environment |
| `dt.security_context` | Dynatrace field with access context, here ALJ_ALJ_PRE | Second source for the environment |
| App code | Application code such as AGPOCLOUDWEBNGINX from `dt.cost.product` | Used to search the real business service |
| Verdict | Task 4 summary: PASS, PASS WITH WARNINGS, or FAIL | Quick right-or-wrong answer |
