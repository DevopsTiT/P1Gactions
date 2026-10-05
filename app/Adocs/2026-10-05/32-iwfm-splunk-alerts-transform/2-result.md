# IWFM Alerts Result

| Detector | Replaces | Settings |
|---|---|---|
| `Prod_EIP_IWFM_EIP006ServiceFailure_High` | EIP - IWFM : EIP006 service Failure Alert | threshold 2, dealerting 5, high |
| `Prod_Compass_IWFMReportException_Normal` | [Prod]ALJ-Compass-IWFMReportException発生 | moving sum 5, threshold 15, medium |
| `Prod_IWFM_AgentErrors_Normal` | IWFM_Errors | threshold 0, dealerting 60, medium |

| Open item | Detail |
|---|---|
| Source fields | Three CONFIRM lines |
| Raw format | Status=FAILURE and LOGLEVEL="Caution" text |
| Paging | Decide for the two _Normal detectors |
| Email | Not included (Terraform detectors only) |
