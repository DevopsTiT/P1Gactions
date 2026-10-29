# Glossary

| Term | What it means |
|---|---|
| `alfrescoacr-batch` | The Splunk index this search reads. |
| Distinct host | One machine, however many events it wrote. |
| `Message` | The number of distinct hosts. |
| `host="Total"` | The single summary row the Splunk search appends. |
| `NOT Message=4` | Keep that row only when the host count is not 4. |
| Statistics (0) | The summary row was removed. The host count is 4. |
| `host.name` | The host name Dynatrace stored on the log. |
| `countDistinct` | Counts different values of a field. |
