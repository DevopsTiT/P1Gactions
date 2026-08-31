# Verify Excel Host Group IDs

Mirror of Daily Files `2026-08-31/27-verify-excel-host-group-ids/`.

See the Daily Files copy for the full guide. Key rule: **Dynatrace is source of truth** for `dt.host_group.id`. Excel column L often has spaces, `C_ALJ_BU` vs live `C_ALI_BU`, and typos like `DATAENGLF` vs `DATAENGI`.

Live MDM ID already proved: `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP`

Verify with keyword search:

```text
fetch logs, from: now()-24h
| filter contains(dt.host_group.id, "CUSTMDMGM")
| summarize log_count = count(), by: { dt.host_group.id }
| sort log_count desc
```

Full steps: Daily Files `27-verify-excel-host-group-ids.md` + `27-verify-excel-host-group-ids-follow.txt`.
