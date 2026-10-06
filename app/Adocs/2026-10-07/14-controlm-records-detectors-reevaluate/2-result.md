# Control-M Re-evaluation Outcome

| Item | Result |
|---|---|
| Terraform | `14-controlm-records-detectors-reevaluate.tf` |
| Detectors | 6, one `for_each` resource `controlm_alerts` |
| Workflows | 0 |
| Severity | `job_abend` high, all others medium |
| PagerDuty | `"0"` on all; `job_abend` needs confirmation |
| Daily emails | Removed; keep seq 31 workflows only if the team still wants them |
| Before apply | Run the 4 check queries and adjust lookback windows |
