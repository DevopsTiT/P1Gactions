# User question (verbatim)

(empty message — screenshot only)

## Context

User shared a Dynatrace screenshot showing an error when running a DQL log query.

**Error:** `Metric selector parse error: line 1:6 at 'logs'`

**Where they ran it:** Data explorer (subtitle: "Query for metrics and transform results")

**Query pasted:**

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE"
})
| filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|njiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

## Issues identified

1. **Wrong UI** — Data explorer accepts metric selectors only, not `fetch logs` DQL
2. **Typo in regex** — `njiFullAddress` should be `kanjiFullAddress`
3. **Missing field names** — kanaFullAddress, contractPersonKanjiName, contractPersonKanaName, subscriberZipCode

## Deliverable requested

1. Explain why the error happens (wrong UI)
2. Exact navigation paths: Logs and Events → Advanced mode, Notebooks → DQL cell, Log viewer with Grail
3. Corrected copy-paste query (all 20 Excel field names)
4. Fallback if tenant has no Grail/logs DQL (classic Log viewer search)
5. Step-by-step Dynatrace UI navigation
6. SRE beginner style

Builds on seq 7 (insurance PII keywords) and seq 6 (discovery).
