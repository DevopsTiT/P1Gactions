# Investigation

Host query window: 13:38:55 to 14:38:55. Executed at 14:38:55.

| Host | Dynatrace count |
|---|---|
| `WPALJA21BF.prprivmgmt.intraxa` | 122,812 |
| `WPALJA21BC.prprivmgmt.intraxa` | 114,665 |
| `WPALJA21C0.prprivmgmt.intraxa` | 112,272 |
| `WPALJA21B9.prprivmgmt.intraxa` | 111,935 |

The four Dynatrace counts add up to 461,684.

The Splunk host popup for the same file was:

| Host | Splunk popup count |
|---|---|
| `WPALJA21BC.prprivmgmt.intraxa` | 32,913 |
| `WPALJA21C0.prprivmgmt.intraxa` | 31,448 |
| `WPALJA21B9.prprivmgmt.intraxa` | 30,971 |
| `WPALJA21BF.prprivmgmt.intraxa` | 30,401 |

Those Splunk counts add up to 125,733. The Events tab said 113,154 on a paused search.

The three content rows are host `WPALJA21BC.prprivmgmt.intraxa`. The visible message code is `YAI.0900.0005I`. The cell ends at `[default][WPA`.
