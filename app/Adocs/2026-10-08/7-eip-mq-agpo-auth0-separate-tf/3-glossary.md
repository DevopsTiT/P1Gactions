# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Terraform configuration | All tf files in one folder, read together | Split files still plan and apply together |
| Provider block | Tells Terraform which plugin to use (Dynatrace) | Must be declared once per folder |
| `for_each` | Create one resource per map entry | Removed; each file now has one plain resource |
| Resource address | Type plus name, like `dynatrace_davis_anomaly_detectors.eip_mq_conn_timeout` | Changing it makes Terraform think it is a new resource |
| `terraform state mv` | Renames a resource in the state file | Avoids destroying and recreating the detector |
