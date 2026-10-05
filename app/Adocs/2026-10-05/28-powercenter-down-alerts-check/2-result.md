# PowerCenter Down Alerts Result

| Outcome | Detail |
|---|---|
| Detectors | 1, `Prod_MWSP_PowerCenter_ServiceDown_High` |
| Replaces | All 3 Splunk alerts |
| Threshold | 0 (change to 2 if query 2 shows constant background lines) |
| Dealerting | 15 minutes quiet |
| Routing | `dt.source_entity` set to the host so the standard flow can read host tags |
| Email | Not included (Terraform only) |
| To confirm | Field replacing `index="powercenter"` |
