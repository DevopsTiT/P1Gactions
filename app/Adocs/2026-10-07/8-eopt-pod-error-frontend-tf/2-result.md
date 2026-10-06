# Result

| Item | Outcome |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.eopt_openpaas_pod_error_frontend` |
| Match | JSON level equals ERROR in any case |
| Notify | medium, email only |
| Next | Find the frontend pods with check.dql, then `terraform plan` |
