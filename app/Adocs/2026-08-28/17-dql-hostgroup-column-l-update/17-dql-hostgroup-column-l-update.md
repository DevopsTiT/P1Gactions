# Host Group Column L Update

```
Spreadsheet has old group in column B?
  │
  ├─ Column L has the correct dt.host_group.id (manual change value)
  │     └─ Formula: ="C_ALJ_BU_" & D & "_A_" & E & "_E_" & F & "_T_" & G
  │
  ├─ Excel fix (documentation)
  │     Select L → Copy → Paste Values into B
  │     └─ Or in B2: =L2 then fill down
  │
  ├─ Dynatrace host group migration
  │     Move each host to its column L group in OneAgent / host settings
  │     └─ Hosts screen must show column L ID before DQL will match
  │
  ├─ DQL filters (seq 11–13 queries)
  │     Replace in(dt.host_group.id, { ... }) with unique-col-l.sh list
  │     └─ Drop C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE for spreadsheet hosts
  │
  ├─ log_count = 0 after switch?
  │     Host not migrated yet → filter host.name + old group temporarily
  │     ID typo → compare Hosts screen to exact column L string
  │
  └─ Per-host PII rules
        Use hostname + column L group (not shared INFRA bucket)
```

| Question | Answer |
| --- | --- |
| What changed? | **Column B** had generic or wrong groups; **column L** has the correct per-app `dt.host_group.id` |
| What to use in DQL? | **Column L values only** — see `unique-col-l.sh` (53 IDs) |
| What to stop using? | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` for HR, MDM, FTP, DFS, EIP, etc. |
| Why it mattered | Six different apps shared one INFRA group — PII rules and inventory were wrong |
| Where to run DQL? | **Logs and Events → Advanced mode** (not Data explorer) |
| After migration | Inventory should show one row per app group (e.g. CUSTMDMGM, PSOFTHRMG), not one big INFRA row |

## Summary

Your Excel sheet builds the correct Dynatrace host group ID in **column L** (`manual change value`). Column B still shows the **old** assignment — often `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` for many unrelated apps. All DQL from seq 11–13 must use **column L IDs**, not column B. This guide gives the hostname mapping, the new `unique-col-l.sh` list, updated inventory and master queries, and Excel steps to copy L into B.

**Important:** Dynatrace only returns logs under a host group after the **host is actually moved** to that group. If inventory shows zero for a column L ID, check **Hosts → Host group** on that server first.

---

## Column B vs column L — what went wrong

| Column | Header | Problem |
| --- | --- | --- |
| B | `dt host_group_id` | Many hosts pointed at shared **INFRA** or outdated BAP / CLAIMS groups |
| L | `manual change value` | Correct per-app ID from hidden columns D–G (dept, app code, env, type) |

**Example from your screenshot:**

| Hostname | Old (column B) | New (column L) |
| --- | --- | --- |
| `AXS-HFTP-01` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | `C_ALJ_BU_MIDDLEWARE_A_FTPSSBTB_E_PRD_T_APP` |
| `S-HQFS-01` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | `C_ALJ_BU_MIDDLEWARE_A_DFS_E_PRD_T_APP` |
| `CEAA0059.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | `C_ALJ_BU_HR_A_PSOFTHRMG_E_PRD_T_APP` |
| `CEAA006B.PRPRIVMGMT.intra` | `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` |
| `CEAA007F.PRPRIVMGMT.intra` | `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | `C_ALJ_BU_MIDDLEWARE_A_HULFT_E_PRD_T_APP` |

---

## Full hostname → column L mapping (spreadsheet rows)

Use **exact strings from column L** in Excel if any cell differs (formula output is source of truth).

| Hostname | Application | Column L (`dt.host_group.id`) |
| --- | --- | --- |
| `AXS-HFTP-01` | FTP SSTB [TS] | `C_ALJ_BU_MIDDLEWARE_A_FTPSSBTB_E_PRD_T_APP` |
| `S-HQFS-01` | DFS [TS] | `C_ALJ_BU_MIDDLEWARE_A_DFS_E_PRD_T_APP` |
| `CEAA0059.PRPRIVMGMT.intra` | People Soft HR | `C_ALJ_BU_HR_A_PSOFTHRMG_E_PRD_T_APP` |
| `CEAA006B.PRPRIVMGMT.intra` | Customer MDM | `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` |
| `CEAA006F.PRPRIVMGMT.intra` | Enterprise Integration Platform | `C_ALJ_BU_MIDDLEWARE_A_EIP_E_PRD_T_APP` |
| `CEAA007F.PRPRIVMGMT.intra` | Hulft [TS] | `C_ALJ_BU_MIDDLEWARE_A_HULFT_E_PRD_T_APP` |
| `CEAA0080.PRPRIVMGMT.intra` | Hulft [TS] | `C_ALJ_BU_MIDDLEWARE_A_HULFT_E_PRD_T_APP` |
| `CEAA0081.PRPRIVMGMT.intra` | Hulft [TS] | `C_ALJ_BU_MIDDLEWARE_A_HULFT_E_PRD_T_APP` |
| `CEAA0088.PRPRIVMGMT.intra` | Tax Payment Report Management | `C_ALJ_BU_DATA_A_TAXRPRTMG_E_PRD_T_APP` |
| `CEAA008F.PRPRIVMGMT.intra` | imageWARE Form Manager | `C_ALJ_BU_MIDDLEWARE_A_IWFM_E_PRD_T_APP` |
| `CEAA0090.PRPRIVMGMT.intra` | imageWARE Form Manager | `C_ALJ_BU_MIDDLEWARE_A_IWFM_E_PRD_T_APP` |
| `CEAA0091.PRPRIVMGMT.intra` | imageWARE Form Manager | `C_ALJ_BU_MIDDLEWARE_A_IWFM_E_PRD_T_APP` |
| `CEAA0092.PRPRIVMGMT.intra` | imageWARE Form Manager | `C_ALJ_BU_MIDDLEWARE_A_IWFM_E_PRD_T_APP` |
| `CEAA101D.PRPRIVMGMT.intra` | BC calc (DB) | `C_ALJ_BU_DAMPOSHIN_A_BCCALC_E_PRD_T_DB` |
| `CEAA204E.prprivmgmt.intra` | ETL Power Center (APP) | `C_ALJ_BU_MIDDLEWARE_A_ETLPCBTCH_E_PRD_T_APP` |
| `CEAA204F.prprivmgmt.intra` | ETL Power Center (APP) | `C_ALJ_BU_MIDDLEWARE_A_ETLPCBTCH_E_PRD_T_APP` |
| `CEAA2050.prprivmgmt.intra` | UDM [TS] | `C_ALJ_BU_MIDDLEWARE_A_UDM_E_PRD_T_APP` |
| `CEAA20BB.prprivmgmt.intra` | Load Runner [TS] | `C_ALJ_BU_PLATFARCH_A_LOADRUNNR_E_PRD_T_APP` |
| `CEAA20CC.prprivmgmt.intra` | Load Runner [TS] | `C_ALJ_BU_PLATFARCH_A_LOADRUNNR_E_PRD_T_APP` |
| `CEAA20F7.prprivmgmt.intra` | Filenet Foundations (APP) | `C_ALJ_BU_DATAENGLF_A_FILENETFN_E_PRD_T_APP` |
| `CEAA2115.prprivmgmt.intra` | Customer MDM | `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` |
| `CEAA2116.prprivmgmt.intra` | Customer MDM | `C_ALJ_BU_MIDDLEWARE_A_CUSTMDMGM_E_PRD_T_APP` |
| `CEAA309A.prprivmgmt.intra` | ETL (DB) | `C_ALJ_BU_PLATFARCH_A_ETLPCBTCH_E_PRD_T_DB` |
| `CEAA309B.prprivmgmt.intra` | Filenet (DB) | `C_ALJ_BU_PLATFARCH_A_FILENETFN_E_PRD_T_DB` |
| `CEAA309C.prprivmgmt.intra` | Filenet (DB) | `C_ALJ_BU_PLATFARCH_A_FILENETFN_E_PRD_T_DB` |
| `CEAA30B3.prprivmgmt.intra` | Tax Payment (DB) | `C_ALJ_BU_DATA_A_TAXRPRTMG_E_PRD_T_DB` |
| `CEAA30A6.prprivmgmt.intra` | BI CCI Performance Simulation (DB) | `C_ALJ_BU_DATADA_A_BICCIPSIM_E_PRD_T_DB` |
| `CEAA30AB.prprivmgmt.intra` | CANweb (DB) | `C_ALJ_BU_DAMPOSHIN_A_CANWEB_E_PRD_T_DB` |

**ADL and platform hosts** (not in the screenshot table) keep their existing column L-style IDs — listed in `unique-col-l.sh`.

---

## Excel — copy column L into column B

1. Click column **L** header → select all data rows with values.
2. **Copy** (Ctrl+C / Cmd+C).
3. Click cell **B2** → **Paste Special → Values** (not formulas).
4. Save the workbook so column B matches column L for documentation and handoffs.

Optional: in **B2** enter `=L2` and fill down — then paste values again so B is static text.

---

## IDs removed from DQL (old column B / seq 13 list)

| Old ID (stop using for spreadsheet hosts) | Replaced by (column L examples) |
| --- | --- |
| `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` | Per-app IDs above (HR, MDM, FTP, DFS, EIP, …) |
| `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP` | `C_ALJ_BU_MIDDLEWARE_A_HULFT_E_PRD_T_APP` |
| `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP` | `C_ALJ_BU_DATA_A_TAXRPRTMG_E_PRD_T_APP` |
| `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_DB` | `C_ALJ_BU_DATA_A_TAXRPRTMG_E_PRD_T_DB` |
| `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_IWFM_E_PRD_T_BE` | `C_ALJ_BU_MIDDLEWARE_A_IWFM_E_PRD_T_APP` |
| `C_ALJ_BU_DATA-INNOVATION-A_MDM_E_PRD_T_APP` | `C_ALJ_BU_MIDDLEWARE_A_CUSTMDMGM_E_PRD_T_APP` |
| `C_ALJ_BU_CLAIMS-RECEPTION-A_ICM_E_PRD_T_APP` | `C_ALJ_BU_DATAENGLF_A_FILENETFN_E_PRD_T_APP` or CUSTMDMGM |
| `C_ALJ_BU_CLAIMS-RECEPTION-A_ICM_E_PRD_T_DB` | `C_ALJ_BU_PLATFARCH_A_FILENETFN_E_PRD_T_DB` |

---

## Updated inventory query (column L — 53 groups)

Run in **Logs and Events → Advanced mode**. Full one-liner also in `17.sh`.

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_ADL_A_AgencyFeeAuto-Send_E_PRD",
    "C_ALJ_BU_ADL_A_Backup_E_DR",
    "C_ALJ_BU_ADL_A_CoreFileServer_E_PRD",
    "C_ALJ_BU_ADL_A_CoreStor_E_PRD",
    "C_ALJ_BU_ADL_A_DataExtractionTool_E_PRD",
    "C_ALJ_BU_ADL_A_DocUpload_E_PRD",
    "C_ALJ_BU_ADL_A_DomainController_E_PRD",
    "C_ALJ_BU_ADL_A_EventLogManagement_E_PRD",
    "C_ALJ_BU_ADL_A_GitRedmine_E_OA",
    "C_ALJ_BU_ADL_A_Hulft_E_PRD",
    "C_ALJ_BU_ADL_A_ILMT_E_PRD",
    "C_ALJ_BU_ADL_A_InformationManagement_E_PRD",
    "C_ALJ_BU_ADL_A_JP1-AJS3_E_DR",
    "C_ALJ_BU_ADL_A_MQ-PDF-Mail_E_PRD",
    "C_ALJ_BU_ADL_A_ORA-WFA_E_PRD",
    "C_ALJ_BU_ADL_A_OracleDB_E_PRD",
    "C_ALJ_BU_ADL_A_Payment_E_PRD",
    "C_ALJ_BU_ADL_A_Proxy_E_PRD",
    "C_ALJ_BU_ADL_A_Rism_E_PRD",
    "C_ALJ_BU_ADL_A_SMTP_E_PRD",
    "C_ALJ_BU_ADL_A_Satellite_E_OA",
    "C_ALJ_BU_ADL_A_Terminal_E_OA",
    "C_ALJ_BU_ADL_A_WSUS_E_PRD",
    "C_ALJ_BU_ADL_A_Web-AP-Server_E_PRD",
    "C_ALJ_BU_ADL_A_Web_E_PRD",
    "C_ALJ_BU_AG-PORTAL-CLOUD_A_AGPORTALAPI_E_PRD_T_PROXY",
    "C_ALJ_BU_CLAIMS-RECEPTION-A_ICM_E_PRD_T_DOCHUB",
    "C_ALJ_BU_DAMPOSHIN_A_BCCALC_E_PRD_T_DB",
    "C_ALJ_BU_DAMPOSHIN_A_CANWEB_E_PRD_T_DB",
    "C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALJ_BU_DATAENGLF_A_FILENETFN_E_PRD_T_APP",
    "C_ALJ_BU_DATA_A_TAXRPRTMG_E_PRD_T_APP",
    "C_ALJ_BU_DATA_A_TAXRPRTMG_E_PRD_T_DB",
    "C_ALJ_BU_DATADA_A_BICCIPSIM_E_PRD_T_DB",
    "C_ALJ_BU_GIC-TOUCHPOINT_A_CANWEB_E_PRD_T_PROXY",
    "C_ALJ_BU_HR_A_PSOFTHRMG_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-A_SITEMINDER_E_PRD_T_RESERVEPROXY",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_ETL_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_HATS_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_CUSTMDMGM_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_DFS_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_EIP_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_EIP_E_PRD_T_DB",
    "C_ALJ_BU_MIDDLEWARE_A_ETLPCBTCH_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_FTPSSBTB_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_IWFM_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_MQ_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE_A_UDM_E_PRD_T_APP",
    "C_ALJ_BU_MSP_A_OUD_E_PRD_T_OUD",
    "C_ALJ_BU_NEW-BUSINESS_A_NBWF_E_PRD_T_BATCH",
    "C_ALJ_BU_PLATFARCH_A_ETLPCBTCH_E_PRD_T_DB",
    "C_ALJ_BU_PLATFARCH_A_FILENETFN_E_PRD_T_DB",
    "C_ALJ_BU_PLATFARCH_A_LOADRUNNR_E_PRD_T_APP"
  })
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

**What you should see after migration:** Separate rows for `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP`, `C_ALJ_BU_HR_A_PSOFTHRMG_E_PRD_T_APP`, etc. The giant `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` bucket should shrink or disappear for migrated hosts.

---

## Per-host verification (hostname + column L)

Use when one host should belong to exactly one column L group:

```text
fetch logs, from: now()-24h
| filter host.name == "CEAA006B.PRPRIVMGMT.intra"
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP")
| summarize log_count = count(), by: { dt.host_group.id, host.name }
```

```text
fetch logs, from: now()-24h
| filter host.name == "CEAA0059.PRPRIVMGMT.intra"
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_HR_A_PSOFTHRMG_E_PRD_T_APP")
| summarize log_count = count(), by: { dt.host_group.id, host.name }
```

---

## Master query — replace ID block only

Take the **Master query** from seq 13 or seq 15. Keep the `summarize { countIf(...) ... } by: { dt.host_group.id }` structure. **Only replace** the `in(dt.host_group.id, { ... })` block with the 53 IDs above (same as inventory).

Keyword regex blocks stay unchanged (seq 7 + seq 10 fixes).

---

## What to update in earlier seq folders

| Seq | Action |
| --- | --- |
| 11 | Replace `unique.sh` host group block with `unique-col-l.sh` |
| 12 | HATS groups unchanged (`HATS`, `CUSTMDMGM` already column-L style) |
| 13 | Replace all 44-ID blocks with 53-ID column L list |
| 15 | Master query — same brace fix, new ID list |
| 5, 9 | Treat column B in old tables as **obsolete**; use mapping table in this seq |

---

## Data flow map

```
Excel HostNames sheet
  columns D,E,F,G (hidden) ──formula──► column L (correct dt.host_group.id)
  column B (old) ──should copy from L──► documentation + runbooks

Host group migration (OneAgent / Dynatrace Hosts)
  hostname ──assigned to──► column L host group entity

Log ingest
  OneAgent on host ──tags──► dt.host_group.id on each log record

DQL (Logs Advanced)
  in(dt.host_group.id, { unique-col-l.sh }) ──► inventory / PII / HATS queries
  host.name + matchesValue(dt.host_group.id, "...") ──► per-host verify

PII masking rules
  scope by column L group (+ host.name for safety during rollout)
```

---

## Related files

| File | Role |
| --- | --- |
| `17-dql-hostgroup-column-l-update.md` | This guide |
| `unique-col-l.sh` | One column L ID per line (53 groups) — paste into DQL |
| `17.sh` | Inventory + per-host verify one-liners |
| `17-dql-hostgroup-column-l-update-follow.txt` | Chat-ready copy steps |
| `13-dql-pii-all-servers/unique.sh` | **Superseded** for spreadsheet hosts — use `unique-col-l.sh` |

## Commands

See `17.sh` for copy-paste DQL and local line count:

```bash
wc -l "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-28/17-dql-hostgroup-column-l-update/unique-col-l.sh"
```
