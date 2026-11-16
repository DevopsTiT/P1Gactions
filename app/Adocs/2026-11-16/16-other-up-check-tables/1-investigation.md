# Investigation

The screenshots are the other up-check tables on the same Splunk dashboard.

| Panel | Host | Status column | Screen value |
|---|---|---|---|
| DC1 Integration Servers | `WPALJA21B8.prprivmgmt.intraxa` | `IS_Result.IS_Status` | `EIP_UP` |
| DC1 Integration Servers | `WPALJA21BB.prprivmgmt.intraxa` | `IS_Result.IS_Status` | `EIP_UP` |
| DC2 Mediator Servers | `WPALJA21BF.prprivmgmt.intraxa` | `MG_Result.MG_Status` | `EIP_UP` |
| DC2 Mediator Servers | `WPALJA21C0.prprivmgmt.intraxa` | `MG_Result.MG_Status` | `EIP_UP` |
| DC2 Integration Servers | `WPALJA21C1.prprivmgmt.intraxa` | `IS_Result.IS_Status` | `EIP_UP` |
| DC2 Integration Servers | `WPALJA21BD.prprivmgmt.intraxa` | `IS_Result.IS_Status` | `EIP_UP` |

Dynatrace already showed these job names on `log.source == "restapi-monitoring"`:

| Job name | JSON body |
|---|---|
| `EIP IS UP check WPALJA21B8` | `{"IS_Result":{"IS_Status":"EIP_UP"}}` |
| `EIP MG UP check WPALJA21B9` | `{"MG_Result":{"MG_Status":"EIP_UP"}}` |
| `EIP MG UP check WPALJA21BC` | `{"MG_Result":{"MG_Status":"EIP_UP"}}` |

`WPALJA21BB`, `WPALJA21BF`, `WPALJA21C0`, `WPALJA21C1`, and `WPALJA21BD` are on the Splunk panels. Their Dynatrace job names have not been opened yet.
