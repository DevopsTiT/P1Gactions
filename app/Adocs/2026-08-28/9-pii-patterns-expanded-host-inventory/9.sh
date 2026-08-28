# DQL PII discovery — expanded inventory — paste into Logs and Events Advanced mode (read-only)
# Step 0 expanded inventory — log count by host group and host (24h)
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_DB","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP","C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_APP","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB"}) | summarize log_count = count(), by: {dt.host_group.id, host.name} | sort log_count desc
# Step 1 all screenshot hosts — log count by host and source (24h)
fetch logs, from: now()-24h | filter in(host.name, {"CEAA0059.PRPRIVMGMT.intra","CEAA006B.PRPRIVMGMT.intra","CEAA006F.PRPRIVMGMT.intra","CEAA007F.PRPRIVMGMT.intra","CEAA0080.PRPRIVMGMT.intra","CEAA0081.PRPRIVMGMT.intra","CEAA0088.PRPRIVMGMT.intra","CEAA008F.PRPRIVMGMT.intra","CEAA0090.PRPRIVMGMT.intra","CEAA0091.PRPRIVMGMT.intra","CEAA0092.PRPRIVMGMT.intra","CEAA101D.PRPRIVMGMT.intra","CEAA204E.prprivmgmt.intra","CEAA204F.prprivmgmt.intra","CEAA2050.prprivmgmt.intra","CEAA20BB.prprivmgmt.intra","CEAA20CC.prprivmgmt.intra","CEAA20F7.prprivmgmt.intra","CEAA2115.prprivmgmt.intra","CEAA2116.prprivmgmt.intra","CEAA309A.prprivmgmt.intra","CEAA309B.prprivmgmt.intra","CEAA309C.prprivmgmt.intra","CEAA30B3.prprivmgmt.intra","CEAA30A6.prprivmgmt.intra","CEAA30AB.prprivmgmt.intra"}) | summarize log_count = count(), by: {host.name, log.source} | sort log_count desc
# People Soft HR CEAA0059 — PII sweep count
fetch logs, from: now()-24h | filter matchesValue(host.name, "CEAA0059*") | filter matchesRegex(content, "(?i)(EMPLID|employee_id|@|\\b\\d{12}\\b)") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# People Soft HR CEAA0059 — EMPLID sample limit 10
fetch logs, from: now()-24h | filter matchesValue(host.name, "CEAA0059*") | filter matchesRegex(content, "(?i)EMPLID[=:\\s]+[A-Z0-9]+") | fields timestamp, log.source, content | limit 10
# Customer MDM all APP hosts — PII sweep count
fetch logs, from: now()-24h | filter in(host.name, {"CEAA006B.PRPRIVMGMT.intra","CEAA2115.prprivmgmt.intra","CEAA2116.prprivmgmt.intra"}) | filter matchesRegex(content, "(?i)(customer_id|CUST_ID|CUST_NAME|address|@)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Customer MDM CEAA006B — customer_id sample limit 10
fetch logs, from: now()-24h | filter host.name == "CEAA006B.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)customer_id[=:\\s]+\\S+") | fields timestamp, log.source, content | limit 10
# Tax Payment APP and DB — PII sweep count
fetch logs, from: now()-24h | filter in(host.name, {"CEAA0088.PRPRIVMGMT.intra","CEAA30B3.prprivmgmt.intra"}) | filter matchesRegex(content, "(?i)(taxpayer_id|account_no|TIN|\\b\\d{12}\\b)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Tax Payment CEAA0088 — taxpayer_id sample limit 10
fetch logs, from: now()-24h | filter host.name == "CEAA0088.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)taxpayer_id[=:\\s]+\\S+") | fields timestamp, log.source, content | limit 10
# Filenet APP and DB — PII sweep count
fetch logs, from: now()-24h | filter in(host.name, {"CEAA20F7.prprivmgmt.intra","CEAA309B.prprivmgmt.intra","CEAA309C.prprivmgmt.intra"}) | filter matchesRegex(content, "(?i)(document_id|insuredPerson|policyNo|customer_id)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Filenet CEAA20F7 — insuredPerson sample limit 10
fetch logs, from: now()-24h | filter host.name == "CEAA20F7.prprivmgmt.intra" | filter matchesPhrase(content, "insuredPerson") | fields timestamp, log.source, content | limit 10
# imageWARE CEAA008F-92 — PII sweep count
fetch logs, from: now()-24h | filter in(host.name, {"CEAA008F.PRPRIVMGMT.intra","CEAA0090.PRPRIVMGMT.intra","CEAA0091.PRPRIVMGMT.intra","CEAA0092.PRPRIVMGMT.intra"}) | filter matchesRegex(content, "(?i)(form_data|applicant_name|address|postal_code|@)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# ETL CEAA204E CEAA204F CEAA309A — PII sweep count
fetch logs, from: now()-24h | filter in(host.name, {"CEAA204E.prprivmgmt.intra","CEAA204F.prprivmgmt.intra","CEAA309A.prprivmgmt.intra"}) | filter matchesRegex(content, "(?i)(CUST_NAME|EMPLID|insuredPerson|INSERT INTO|/etl/)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# UDM CEAA2050 — insurance field sweep count
fetch logs, from: now()-24h | filter host.name == "CEAA2050.prprivmgmt.intra" | filter matchesRegex(content, "(?i)(subscriberAddr|insuredPerson|kanjiFullAddress|loginId)") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# Load Runner CEAA20BB CEAA20CC — credential sweep count
fetch logs, from: now()-24h | filter in(host.name, {"CEAA20BB.prprivmgmt.intra","CEAA20CC.prprivmgmt.intra"}) | filter matchesRegex(content, "(?i)(web_set_user|lr_save_string|password|passwd)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Hulft CEAA007F CEAA0080 CEAA0081 — credential and path sweep count
fetch logs, from: now()-24h | filter in(host.name, {"CEAA007F.PRPRIVMGMT.intra","CEAA0080.PRPRIVMGMT.intra","CEAA0081.PRPRIVMGMT.intra"}) | filter matchesRegex(content, "(?i)(password|passwd|user\\s*=|/[^\\s]+\\.(csv|txt|xml|dat))") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# EIP CEAA006F — payload error sweep count
fetch logs, from: now()-24h | filter host.name == "CEAA006F.PRPRIVMGMT.intra" | filter matchesRegex(content, "(?i)(error|exception|payload|customer_id|EMPLID)") | summarize hit_count = count(), by: {log.source} | sort hit_count desc
# Combined insurance keyword sweep — seq 7 link — count by host
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP","C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_APP","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB"}) | filter matchesRegex(content, "(?i)(insuredPerson|subscriberGender|subscriberDOB|subscriberAddr|subscriberPh|insuredGender|insuredDOB|insuredPersonKanjiName|insuredPersonKanaName|contractPersonKanjiName|contractPersonKanaName|subscriberZipCode|kanaFullAddress|kanjiFullAddress|displayName|loginId|lastName|lastNameKana|dob|telNumberOld)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Insurance loginId sample on imageWARE CEAA008F limit 10
fetch logs, from: now()-24h | filter host.name == "CEAA008F.PRPRIVMGMT.intra" | filter matchesPhrase(content, "loginId") | fields timestamp, log.source, content | limit 10
# Japan mobile phone 090-080-070 — count high-PII hosts
fetch logs, from: now()-24h | filter in(host.name, {"CEAA0059.PRPRIVMGMT.intra","CEAA006B.PRPRIVMGMT.intra","CEAA0088.PRPRIVMGMT.intra","CEAA2115.prprivmgmt.intra","CEAA20F7.prprivmgmt.intra"}) | filter matchesRegex(content, "\\b0[789]0\\d{8}\\b") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# My Number 12-digit — count high-PII hosts
fetch logs, from: now()-24h | filter in(host.name, {"CEAA0059.PRPRIVMGMT.intra","CEAA006B.PRPRIVMGMT.intra","CEAA0088.PRPRIVMGMT.intra","CEAA30B3.prprivmgmt.intra"}) | filter matchesRegex(content, "\\b\\d{12}\\b") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# Email — count all expanded inventory hosts
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_DB","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP","C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_APP","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB"}) | filter matchesRegex(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Password token Bearer — count all expanded inventory
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_DB","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP","C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_APP","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB"}) | filter matchesRegex(content, "(?i)(password|passwd|token|Bearer)\\s*[=:]\\s*\\S+") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# DB hosts all six — SQL PII sweep count
fetch logs, from: now()-24h | filter in(host.name, {"CEAA101D.PRPRIVMGMT.intra","CEAA309A.prprivmgmt.intra","CEAA309B.prprivmgmt.intra","CEAA309C.prprivmgmt.intra","CEAA30B3.prprivmgmt.intra","CEAA30A6.prprivmgmt.intra","CEAA30AB.prprivmgmt.intra"}) | filter matchesRegex(content, "(?i)(SELECT\\s+.*\\b(NAME|ADDR|PHONE|EMAIL|CUST_)\\b|bind\\s*[#:]?\\d+|jdbc:|password=)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc
# DB host CEAA30B3 Tax — SQL sample limit 10
fetch logs, from: now()-24h | filter host.name == "CEAA30B3.prprivmgmt.intra" | filter matchesRegex(content, "(?i)(SELECT|INSERT|UPDATE).*") | fields timestamp, log.source, content | limit 10
# DB host CEAA309B Filenet — bind variable sample limit 10
fetch logs, from: now()-24h | filter host.name == "CEAA309B.prprivmgmt.intra" | filter matchesRegex(content, "(?i)bind\\s*[#:]?\\d+") | fields timestamp, log.source, content | limit 10
# DB host CEAA30AB CANweb — loginId sample limit 10
fetch logs, from: now()-24h | filter host.name == "CEAA30AB.prprivmgmt.intra" | filter matchesPhrase(content, "loginId") | fields timestamp, log.source, content | limit 10
# Broad keyword sweep — count by host
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_DB","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP","C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_APP","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB"}) | filter matchesRegex(content, "(?i)(EMPLID|customer_id|taxpayer_id|insuredPerson|loginId|password|passwd|Bearer)") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
# Weekly sweep expanded inventory — summarize only 7d
fetch logs, from: now()-7d | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_DB","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_APP","C_ALJ_BU_DATA-INNOVATION_A_MDM_E_PRD_T_APP","C_ALJ_BU_CLAIMS-RECEPTION_A_ICM_E_PRD_T_DB"}) | filter matchesPhrase(content, "@") | summarize hit_count = count(), by: {host.name, log.source} | sort hit_count desc | limit 50
