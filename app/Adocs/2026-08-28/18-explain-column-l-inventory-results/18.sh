# Seq 18 — verify top groups from column L inventory screenshot (paste exact IDs from your table)
fetch logs, from: now()-24h | filter matchesValue(dt.host_group.id, "C_ALI_BU_PLATFARCH_A_FILENETFN_E_PRD_T_APP") | summarize log_count = count(), by: { dt.host_group.id }
fetch logs, from: now()-24h | filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP") | summarize log_count = count(), by: { dt.host_group.id }
fetch logs, from: now()-24h | filter matchesValue(dt.host_group.id, "C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP") | summarize log_count = count(), by: { dt.host_group.id }
