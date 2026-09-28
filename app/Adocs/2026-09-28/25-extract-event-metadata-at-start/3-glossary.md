# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Event metadata | All fields in the trigger event JSON | Available at start without any API call. |
| entity_tags | Tags of the affected entity as "[Context]key:value" | Main source of routing hints. |
| META_KEYS | Setting listing tag names per SILVA field | Controls which tags feed which field. |
| Security context | Access labels like ALJ_EIP_PRD | Last part often shows the environment. |
| Auto-tag rule | Dynatrace rule that adds tags automatically | Way to put SILVA names into metadata. |
| sys_choice | SILVA table of dropdown values | Shows valid Environment labels. |
| Source | Where a routed value came from (map, tag, default) | Explains each field on the ticket. |
