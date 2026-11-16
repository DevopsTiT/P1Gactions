# Investigation

The search is `index=eip1015` and `sourcetype=eip_mediator_serverlog`. The `(index=* OR index=_*)` term does not add another index.

The Events tab shows 113,154 events. The search is paused.

The source popup shows one file and 125,733 events:

`/opt/softwareag/log/1015/apigw5590/server.log`

The host popup shows four hosts. Those four counts add up to 125,733.

| Host | Count |
|---|---|
| `WPALJA21BC.prprivmgmt.intraxa` | 32,913 |
| `WPALJA21C0.prprivmgmt.intraxa` | 31,448 |
| `WPALJA21B9.prprivmgmt.intraxa` | 30,971 |
| `WPALJA21BF.prprivmgmt.intraxa` | 30,401 |

A sample line is host `WPALJA21C0.prprivmgmt.intraxa` at `2026-11-16 14:32:55.045 JST`. The start of the line is `[YAI.0102.0011]`. Later text on the event view includes `API: pol`.

The chart uses a shared time picker. The page URL is `earliest=-60m@m` and `latest=now`.

The interesting-fields list shows 34 values for `API`. The chart limit is 101, so every current API name fits.
