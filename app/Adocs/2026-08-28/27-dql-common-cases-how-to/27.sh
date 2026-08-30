#!/usr/bin/env bash
# Dynatrace Logs and Events → Advanced mode
# Case 1 inventory
fetch logs, from: now()-24h | filter in(dt.host_group.id, { "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP", "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP" }) | summarize log_count = count(), by: { dt.host_group.id } | sort log_count desc
# Case 4 phrase
fetch logs, from: now()-24h | filter matchesPhrase(content, "rawDataList") | summarize hit_count = count(), by: { dt.host_group.id } | sort hit_count desc
# Case 5 PII per group
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)(insuredPerson|loginId)") | summarize hit_count = count(), by: { dt.host_group.id } | sort hit_count desc
# Case 6 countIf master
fetch logs, from: now()-24h | summarize { hits_keyword = countIf(matchesRegex(content, "(?i)(insuredPerson|loginId)")), hits_hats = countIf(matchesPhrase(content, "rawDataList")), total_logs = count() }, by: { dt.host_group.id } | sort hits_keyword desc
# Case 7 drill
fetch logs, from: now()-24h | filter matchesPhrase(content, "rawDataList") | summarize hit_count = count(), by: { host.name, log.source } | sort hit_count desc
# Case 8 sample
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)loginId") | fields timestamp, host.name, log.source, content | sort timestamp desc | limit 10
