# Final Keys Confirmed On INC30340215

## Decision Tree

```
Re-check INC30340215 with the final keys
 ├─ u_business_service   filled → Business service   ✔
 ├─ cmdb_ci              filled → Service Offering   ✔
 ├─ u_configuration_item filled → Configuration item ✔
 ├─ u_application        empty  → not used by this incident → do not send
 └─ u_business_process   empty  → not used by this incident → do not send
Next → re-import TEST workflow → run → send result → OPEN v7
```

## Short Takeaway

| Question | Answer |
|---|---|
| Are the three keys right? | Yes. All three hold exactly what the form shows. |
| u_application and u_business_process | Empty here. Leave them out of the payload. |
| First command error | `[200~` paste artifact again. The second run is the real result. |
| Workflow | Already uses these keys. Nothing more to change. |
| Next | Run the TEST workflow on a real problem and send the validate-extraction result |

## Summary

The reference incident confirms the mapping: Business service is `u_business_service`, Service Offering is `cmdb_ci`, and Configuration item is `u_configuration_item`. The TEST workflow already sends exactly these, so the next proof is a workflow run.

## Result From Your Query

| Key | Display value | sys_id |
|---|---|---|
| `u_business_service` | Third Party Services Monitoring Application_02-11-2022 11:25:12 | 37273dbc1b0f7c50114e0826464bcbf8 |
| `cmdb_ci` | Third Party Services Monitoring Application_02-11-2022 11:25:12 - AXA XL - Production - Silver_24-08-2023 17:00:33 | cfbf255f1b03b49416deb166464bcb4b |
| `u_configuration_item` | ts12.hk.intraxa | 1dfdcf8adb8dfa40251af9971d961941 |
| `u_application` | empty | empty |
| `u_business_process` | empty | empty |

## Fixing The Paste Error

| Symptom | Cause | Fix |
|---|---|---|
| `[200~curl: command not found` then `jq: 1 compile error` | Git Bash bracketed paste wraps text in `[200~ ... ~` | Paste again, or run `bind 'set enable-bracketed-paste off'` once in the terminal |

## Data Flow

```
INC30340215 ──GET──► u_business_service ✔  cmdb_ci ✔  u_configuration_item ✔
TEST workflow build-payload ──► same three keys ──► validate-extraction (GET only)
```

## Related Files

| File | What it is |
|---|---|
| `../4-v7-test-extraction-validate/4-v7-test-extraction-validate.workflow.yaml` | TEST workflow with the final keys |
| `../15-silva-configuration-item-key/` | How u_configuration_item was found |
| `16.sh` | Commands |
