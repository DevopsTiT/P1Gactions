#!/usr/bin/env bash
# Run in Dynatrace: Logs and Events → Advanced mode
# Example 1 inventory
fetch logs, from: now()-24h | filter in(dt.host_group.id, { "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP" }) | summarize log_count = count(), by: { dt.host_group.id } | sort log_count desc
# Example 2 PII keyword one group
fetch logs, from: now()-24h | filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP") | filter matchesRegex(content, "(?i)(insuredPerson|loginId|customer_id)") | summarize hit_count = count(), by: { dt.host_group.id }
# Example 3 drill host log.source
fetch logs, from: now()-24h | filter matchesPhrase(content, "rawDataList") | summarize hit_count = count(), by: { dt.host_group.id, host.name, log.source } | sort hit_count desc
# Example 4 countIf mini master
fetch logs, from: now()-24h | filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP") | summarize { hits_keyword = countIf(matchesRegex(content, "(?i)(insuredPerson|loginId)")), hits_hats = countIf(matchesPhrase(content, "rawDataList")), total_logs = count() }, by: { dt.host_group.id }
# Example 5 sample limit 10
fetch logs, from: now()-24h | filter matchesRegex(content, "(?i)loginId") | fields timestamp, host.name, log.source, content | sort timestamp desc | limit 10
