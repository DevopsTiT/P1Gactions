# DQL PII discovery — paste into Dynatrace Logs Advanced mode or Notebook (read-only)
# Step 0 inventory — log count by host group and host (24h)
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"}) | summarize log_count = count(), by: {dt.host_group.id, host.name} | sort log_count desc
# Email — count by host and log source (24h)
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"}) | filter matchesRegex(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Email — sample HR host EAA0059
fetch logs, from: now()-24h | filter host.name == "EAA0059.PRPRIVMGMT.intra" | filter matchesRegex(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}") | fields timestamp, log.source, content | limit 10
# EMPLID — count on HR host
fetch logs, from: now()-24h | filter host.name == "EAA0059.PRPRIVMGMT.intra" | filter matchesPhrase(content, "EMPLID") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# EMPLID — sample on HR host
fetch logs, from: now()-24h | filter host.name == "EAA0059.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)EMPLID[=:\\s]+[A-Z0-9]+") | fields timestamp, log.source, content | limit 10
# My Number 12-digit — count high-PII hosts
fetch logs, from: now()-24h | filter in(host.name, {"EAA0059.PRPRIVMGMT.intra","EAA006B.PRPRIVMGMT.intra","EAA0088.PRPRIVMGMT.intra"}) | filter matchesRegex(content, "\\b\\d{12}\\b") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# My Number — sample HR host
fetch logs, from: now()-24h | filter host.name == "EAA0059.PRPRIVMGMT.intra" | filter matchesRegex(content, "\\b\\d{12}\\b") | fields timestamp, log.source, content | limit 10
# customer_id — count MDM host
fetch logs, from: now()-24h | filter host.name == "EAA006B.PRPRIVMGMT.intra" | filter matchesPhrase(content, "customer_id") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# customer_id — sample MDM host
fetch logs, from: now()-24h | filter host.name == "EAA006B.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)customer_id[=:\\s]+\\S+") | fields timestamp, log.source, content | limit 10
# taxpayer_id — count Tax host
fetch logs, from: now()-24h | filter host.name == "EAA0088.PRPRIVMGMT.intra" | filter matchesPhrase(content, "taxpayer_id") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# taxpayer_id — sample Tax host
fetch logs, from: now()-24h | filter host.name == "EAA0088.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)taxpayer_id[=:\\s]+\\S+") | fields timestamp, log.source, content | limit 10
# Password token Bearer — count all inventory
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"}) | filter matchesRegex(content, "(?i)(password|passwd|token|Bearer)\\s*[=:]\\s*\\S+") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Password — sample HULFT hosts
fetch logs, from: now()-24h | filter in(host.name, {"EAA007F.PRPRIVMGMT.intra","EAA0080.PRPRIVMGMT.intra","EAA0081.PRPRIVMGMT.intra"}) | filter matchesRegex(content, "(?i)(password|passwd|user)\\s*[=:]\\s*\\S+") | fields timestamp, log.source, content | limit 10
# Credit card long digits — count Tax host
fetch logs, from: now()-24h | filter host.name == "EAA0088.PRPRIVMGMT.intra" | filter matchesRegex(content, "\\b(?:\\d[ -]*?){13,19}\\b") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# Credit card — sample Tax host
fetch logs, from: now()-24h | filter host.name == "EAA0088.PRPRIVMGMT.intra" | filter matchesRegex(content, "\\b(?:\\d[ -]*?){13,19}\\b") | fields timestamp, log.source, content | limit 10
# Broad @ symbol — count by host
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"}) | filter matchesPhrase(content, "@") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Broad keyword sweep — count by host
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"}) | filter matchesRegex(content, "(?i)(EMPLID|customer_id|taxpayer_id|password|passwd|Bearer)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Per-host EAA0059 People Soft HR
fetch logs, from: now()-24h | filter host.name == "EAA0059.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)(EMPLID|employee_id|@|\\b\\d{12}\\b)") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# Per-host EAA006B Customer MDM
fetch logs, from: now()-24h | filter host.name == "EAA006B.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)(customer_id|CUST_ID|CUST_NAME|address|@)") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# Per-host EAA0088 Tax Payment
fetch logs, from: now()-24h | filter host.name == "EAA0088.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)(taxpayer_id|account_no|TIN|\\b\\d{12}\\b)") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# Per-host HULFT EAA007F EAA0080 EAA0081
fetch logs, from: now()-24h | filter in(host.name, {"EAA007F.PRPRIVMGMT.intra","EAA0080.PRPRIVMGMT.intra","EAA0081.PRPRIVMGMT.intra"}) | filter matchesRegex(content, "(?i)(password|passwd|user\\s*=|/[^\\s]+\\.(csv|txt|xml|dat))") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Per-host imageWARE EAA008F EAA0090 EAA0091 EAA0092
fetch logs, from: now()-24h | filter in(host.name, {"EAA008F.PRPRIVMGMT.intra","EAA0090.PRPRIVMGMT.intra","EAA0091.PRPRIVMGMT.intra","EAA0092.PRPRIVMGMT.intra"}) | filter matchesRegex(content, "(?i)(form_data|applicant_name|address|postal_code|@)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Per-host EAA006F EIP
fetch logs, from: now()-24h | filter host.name == "EAA006F.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)(error|exception|payload|customer_id|EMPLID)") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# Per-host FTP SSTB wildcard
fetch logs, from: now()-24h | filter matchesValue(host.name, "*-HFTP-01.ads-jp.intraxa") | filter matchesRegex(content, "(?i)(password|passwd|user\\s*=|/[^\\s]+\\.(csv|txt|xml|dat))") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Per-host S-HQFS-01 DFS
fetch logs, from: now()-24h | filter host.name == "S-HQFS-01.ads-jp.intraxa" | filter matchesPhrase(content, "@") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# Per-host CEAA101D BC calc
fetch logs, from: now()-24h | filter host.name == "CEAA101D.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)(@|\\b\\d{12}\\b|customer_id)") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# Host group C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE
fetch logs, from: now()-24h | filter matchesValue(dt.host_group.id, "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE") | filter matchesRegex(content, "(?i)(EMPLID|customer_id|password|@)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Host group C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP
fetch logs, from: now()-24h | filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP") | filter matchesRegex(content, "(?i)(password|passwd|user\\s*=|/[^\\s]+\\.(csv|txt|xml|dat))") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Host group C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP
fetch logs, from: now()-24h | filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP") | filter matchesRegex(content, "(?i)(taxpayer_id|account_no|\\b\\d{12}\\b)") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# Host group C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE
fetch logs, from: now()-24h | filter matchesValue(dt.host_group.id, "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE") | filter matchesRegex(content, "(?i)(form_data|applicant_name|address|@)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Weekly sweep — inventory 7d (summarize only)
fetch logs, from: now()-7d | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"}) | filter matchesPhrase(content, "@") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Quick spot check — email on HR last 1h
fetch logs, from: now()-1h | filter host.name == "EAA0059.PRPRIVMGMT.intra" | filter matchesRegex(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
