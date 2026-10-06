# Result

| Item | Outcome |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.powercenter` with 3 keys |
| Keys | service_down_0031, process_stop, powercenter_down |
| Recommendation | Keep process_stop; disable the other two |
| Next | Find the log source, then `terraform plan` (3 to add) |
