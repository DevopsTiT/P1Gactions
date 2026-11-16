# Result

Paste one query per panel. Each one keeps the newest status for each host.

DC1 Integration Servers uses `IS_Result.IS_Status` for `WPALJA21B8` and `WPALJA21BB`.

DC2 Mediator Servers uses `MG_Result.MG_Status` for `WPALJA21BF` and `WPALJA21C0`.

DC2 Integration Servers uses `IS_Result.IS_Status` for `WPALJA21C1` and `WPALJA21BD`.

The full queries are in `16-other-up-check-tables.dql`.

If a panel returns no rows, change `from: now()-3m` to `from: now()-24h`. If it is still empty, remove the `IS UP` or `MG UP` line and keep the short host code.
