# Question — Find HATS rawDataList PII Logs (seq 12)

## User ask

For example this is the result — how to find (logs like the screenshot)?

## Screenshot context

- **UI:** Dynatrace **Logs** viewer (correct — not Data explorer)
- **Time:** ~12:19 JST, volume spike ~12:20
- **Columns:** timestamp, log.source, dt.host_group.id, dt.security_context

### Host groups visible

| dt.host_group.id | dt.security_context |
| --- | --- |
| `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP` | `ALJ-MIDDLEWARE-SHARED-PRODUCT-HATS-P` |
| `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` | `ALJ-DATAENGLF-CUSTMDMGM-PRD` |

### Log content

- Java: `j.c.axa.pis.hats.service.impl.ProcessNdServiceImpl - Finish ND processing.`
- JSON-like: `HatsProcessResponse is {'ndResponses': ...}`
- Field: **`rawDataList`** with alphanumeric + Japanese Kanji/Kana (likely PII)
- Labels in payload: TXID, OPID, PN, 保険金, etc.
- log.source: **SystemOut**

## Requirements

1. DQL to find by `dt.host_group.id` (HATS, CUSTMDMGM)
2. Filter by `log.source` = SystemOut
3. Filter by content: ProcessNdServiceImpl, HatsProcessResponse, rawDataList
4. Find PII inside rawDataList (Japanese chars, field names)
5. Count per host group
6. Sample query for full content (like screenshot sidebar)
7. Link to seq 11 workflow (1A dashboard, drill-down)
8. Note: seq 11 `unique.sh` may not include HATS or DATAENGLF host groups — add them

## Answer

`12-dql-find-hats-rawdata-pii-example.md`
