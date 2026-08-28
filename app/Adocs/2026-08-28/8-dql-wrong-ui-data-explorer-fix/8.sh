# Paste into Logs and Events → Advanced mode (NOT Data explorer)
# Combined keyword sweep — all 20 insurance PII field names
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE"}) | filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)") | summarize hit_count = count(), by: { host.name, log.source } | sort hit_count desc | limit 50
# Sample after count > 0 — limit 10 only (raw PII)
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE"}) | filter matchesRegex(content, "(?i)(insuredPersonKanjiName|displayName|loginId|telNumberOld)[=:\\s]+\\S+") | fields timestamp, host.name, log.source, content | limit 10
# Classic Log viewer fallback (no DQL) — search one field name
"insuredPersonKanjiName"
# git add (run only when user asks to commit)
# git -C /Users/k/Codes/Pra/P1GithubActions/P1Gactions add app/Adocs/2026-08-28/8-dql-wrong-ui-data-explorer-fix/
