# Insurance PII keyword discovery and verification — paste into Dynatrace Logs Advanced mode or Notebook
# Combined keyword sweep — count all 20 Excel field names (24h, AXA scope)
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"}) | filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|\\bdob\\b|telNumberOld)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Combined keyword sweep — sample
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)(insuredPersonKanjiName|displayName|loginId|telNumberOld)[=:\\s]+\\S+") | fields timestamp, host.name, log.source, content | limit 10
# Single field phrase — insuredPersonKanjiName count
fetch logs, from: now()-24h | filter matchesPhrase(content, "insuredPersonKanjiName") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Single field regex — insuredPersonKanjiName with value
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)insuredPersonKanjiName[=:\\s]+\\S+") | fields timestamp, host.name, log.source, content | limit 10
# JSON key — loginId
fetch logs, from: now()-24h | filter matchesRegex(content, "\"loginId\"\\s*:") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Category names Kanji — count
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)(insuredPerson|insuredPersonKanjiName|contractPersonKanjiName|displayName|lastName|kanjiFullAddress)[=:\\s]+") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Category names Kanji — sample with Japanese chars
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)(insuredPersonKanjiName|displayName|lastName)[=:\\s]+[\\u4E00-\\u9FFF々〆ヵヶ\\s　]+") | fields timestamp, log.source, content | limit 10
# Category names Kana — count
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)(insuredPersonKanaName|contractPersonKanaName|lastNameKana|kanaFullAddress)[=:\\s]+") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Category names Kana — sample
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)(lastNameKana|insuredPersonKanaName)[=:\\s]+[\\u30A0-\\u30FFァ-ヶー\\s　]+") | fields timestamp, log.source, content | limit 10
# Category address — count
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)(subscriberAddr|kanaFullAddress|kanjiFullAddress)[=:\\s]+\\S+") | filter not matchesPhrase(content, "<null>") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Category DOB — count
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)(subscriberDOB|insuredDOB|\\bdob\\b)[=:\\s]+\\d{4}/\\d{1,2}/\\d{1,2}") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Category DOB — sample
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)\\bdob[=:\\s]+\\d{4}/\\d{1,2}/\\d{1,2}") | fields timestamp, log.source, content | limit 10
# Category phone — count (090/080/070)
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)(subscriberPh|telNumberOld)[=:\\s]+0[789]0\\d{8}") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Category gender — count
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)(subscriberGender|insuredGender)[=:\\s]+\\S+") | filter not matchesPhrase(content, "null") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Category zip — count
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)subscriberZipCode[=:\\s]+(〒?\\d{3}-?\\d{4}|\\d{7})") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Category loginId — count
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)loginId[=:\\s]+[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Category loginId — sample
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)loginId[=:\\s]+\\S+") | fields timestamp, log.source, content | limit 10
# Japanese PII broad sweep — phone + DOB + zip with insurance keys
fetch logs, from: now()-24h | filter matchesRegex(content, "0[789]0\\d{8}|\\d{4}/\\d{1,2}/\\d{1,2}|〒?\\d{3}-?\\d{4}") | filter matchesRegex(content, "(?i)(insuredPerson|loginId|telNumberOld|dob|subscriber)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Post-mask verification — Kanji still after insuredPersonKanjiName key (should be zero)
fetch logs, from: now()-1h | filter matchesRegex(content, "(?i)insuredPersonKanjiName[=:\\s]+[\\u4E00-\\u9FFF]") | fields timestamp, host.name, content | limit 10
# Post-mask verification — raw phone after telNumberOld (should be zero)
fetch logs, from: now()-1h | filter matchesRegex(content, "(?i)telNumberOld[=:\\s]+0[789]0\\d{8}") | fields timestamp, host.name, content | limit 10
# Post-mask verification — raw email after loginId (should be zero)
fetch logs, from: now()-1h | filter matchesRegex(content, "(?i)loginId[=:\\s]+[a-zA-Z0-9._%+-]+@") | filter not matchesPhrase(content, "loginId=***") | fields timestamp, host.name, content | limit 10
# Scoped to MDM host EAA006B — combined sweep
fetch logs, from: now()-24h | filter host.name == "EAA006B.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)(insuredPerson|displayName|loginId|telNumberOld|kanaFullAddress|kanjiFullAddress)") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
