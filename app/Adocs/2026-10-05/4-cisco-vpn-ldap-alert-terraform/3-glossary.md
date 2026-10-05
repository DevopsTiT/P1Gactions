# Glossary

| Term | What it means |
|---|---|
| Terraform | A tool that creates and updates infrastructure from code files |
| Provider | The Terraform plugin that talks to a system; here `dynatrace-oss/dynatrace` |
| Resource | One thing Terraform manages; here one anomaly detector |
| `dynatrace_davis_anomaly_detectors` | Terraform resource for a custom alert in the Anomaly Detection app |
| Analyzer | The algorithm that decides when to alert; here a static threshold |
| Event template | The fields put on the Davis event when the alert fires |
| Execution settings | Who the query runs as and timing options |
| Actor | The service user the query runs on behalf of |
| Platform token | A Dynatrace token for the newer platform APIs |
| `matchesValue` | DQL function that compares a value with wildcard support |
| tfvars | A file with variable values for Terraform |
