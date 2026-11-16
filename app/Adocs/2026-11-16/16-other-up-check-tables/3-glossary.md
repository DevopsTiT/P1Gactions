# Glossary

| Word | What it means |
|---|---|
| Mediator server | The MG up-check. The Splunk column is `MG_Result.MG_Status`. |
| Integration server | The IS up-check. The Splunk column is `IS_Result.IS_Status`. |
| `EIP_UP` | The status value on every row in these screenshots. The check says the server is up. |
| `restapi.job_name` | The Dynatrace field that holds the check name, such as `EIP IS UP check WPALJA21B8`. |
| `restapi.url` | The check URL. The host name is the part between `://` and the port. |
| `takeFirst` | After sorting newest first, keep the first status for that host. |
| DC1 | The first site on this dashboard. Hosts B8, BB, B9, and BC. |
| DC2 | The second site on this dashboard. Hosts BF, C0, C1, and BD. |
