# Verification DQL — paste into Dynatrace Logs Advanced mode or Notebook (read-only)
# Host group inventory check (24h)
fetch logs, from: now()-24h | filter in(dt.host_group.id, {"C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE","C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP","C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP","C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"}) | summarize count(), by: {dt.host_group.id, host.name} | sort count desc
# HR host raw email leak check
fetch logs, from: now()-1h | filter host.name == "EAA0059.PRPRIVMGMT.intra" | filter matchesPhrase(content, "@") | filter not matchesPhrase(content, "xxx@xxx.xxx") | fields timestamp, content, log.source | limit 20
# HR host EMPLID leak check
fetch logs, from: now()-1h | filter host.name == "EAA0059.PRPRIVMGMT.intra" | filter matchesPhrase(content, "EMPLID") | filter not matchesPhrase(content, "EMPLID=***") | limit 20
# Tax host taxpayer_id leak check
fetch logs, from: now()-1h | filter host.name == "EAA0088.PRPRIVMGMT.intra" | filter matchesPhrase(content, "taxpayer_id") | filter not matchesPhrase(content, "taxpayer_id=***") | limit 20
# HULFT password leak check
fetch logs, from: now()-1h | filter in(host.name, {"EAA007F.PRPRIVMGMT.intra","EAA0080.PRPRIVMGMT.intra","EAA0081.PRPRIVMGMT.intra"}) | filter matchesPhrase(content, "password=") | filter not matchesPhrase(content, "password=***") | limit 20
# imageWARE email leak check (priority hosts)
fetch logs, from: now()-1h | filter in(host.name, {"EAA008F.PRPRIVMGMT.intra","EAA0090.PRPRIVMGMT.intra","EAA0091.PRPRIVMGMT.intra","EAA0092.PRPRIVMGMT.intra"}) | filter matchesPhrase(content, "@") | filter not matchesPhrase(content, "xxx@xxx.xxx") | limit 20
# OpenPipeline applied on tax host
fetch logs, from: now()-1h | filter host.name == "EAA0088.PRPRIVMGMT.intra" | filter isNotNull(dt.openpipeline.pipelines) | fields timestamp, dt.openpipeline.pipelines, content | limit 10
