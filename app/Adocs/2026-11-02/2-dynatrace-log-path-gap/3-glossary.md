# Glossary

| Term | What it means |
|---|---|
| Log source | The file path on the server. Here, `/app/ICM_CPW/log/ap/default.log`. |
| Included | The Dynatrace agent is set up to read that file and store the lines. |
| Host group | A set of hosts in Dynatrace. A setting on the group applies to each host in it. |
| `dynatrace_log_storage` | Terraform that decides which matched logs are stored. |
| `send_to_storage` | `true` means keep the matched lines in Dynatrace. |
| `MATCHES` | The path must match the string in `values`. |
| `dynatrace_log_custom_source` | Terraform that tells the agent to pick up a file that is not collected by default. |
| PII | Personal data. The chat title is about masking it. This note does not show the mask. |
