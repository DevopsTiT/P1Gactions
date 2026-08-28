# User question (verbatim)

give me the dql how to search these pii first

## Context

They have AXA production hosts from Prod-HostGroupUpdate spreadsheet. Previous guide at seq 5: `5-dynatrace-pii-hostgroup-axa`. They want DQL to **find/search PII first** (discovery/audit BEFORE masking) — not masking DQL yet.

Hosts from spreadsheet:
- EAA0059 People Soft HR (C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE)
- EAA006B Customer MDM
- EAA0088 Tax Payment (C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP)
- EAA007F/80/81 Hulft (C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP)
- EAA008F-92 imageWARE
- FTP, DFS, EIP, BC calc

## Deliverable requested

Practical DQL discovery queries:
1. Decision tree: what to search first
2. Per-PII-type search queries (email, EMPLID, 12-digit My Number, customer_id, taxpayer_id, password/token, credit card patterns)
3. Per-host queries from spreadsheet
4. Per-host-group queries
5. Broad "any @ symbol" / regex discovery
6. How to run in Dynatrace UI (Logs, Notebooks, Advanced mode)
7. Time window tips (now()-1h, -24h, -7d)
8. How to interpret results (count, sample content, escalate)
9. Safety: read-only audit, don't export raw PII broadly

Link back to seq 5 for masking after discovery.
