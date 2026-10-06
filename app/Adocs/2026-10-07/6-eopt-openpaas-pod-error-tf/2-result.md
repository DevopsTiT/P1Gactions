# Result

| Item | Outcome |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.eopt_openpaas_pod_error` |
| Match | "Z ERROR " in eopt pod logs |
| Notify | medium, email only |
| Next | check.dql queries 1, 3 and 4, then `terraform plan` |
