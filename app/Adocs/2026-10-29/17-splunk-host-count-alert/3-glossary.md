# Glossary

| Term | What it means |
|---|---|
| Index | The Splunk bucket of events. This search uses `alfrescoacr-batch`. |
| `stats count by host` | One row for each host, plus how many events that host wrote. |
| `fields - count` | Removes the event-count column. The host rows stay. |
| `appendpipe` | Runs a small search on the current rows and adds the result underneath. |
| `Message` | The number of host rows. |
| `host="Total"` | The label on the one summary row. |
| `NOT Message=4` | Keep that summary row only when the host count is not 4. |
| Statistics (0) | The final table has no row. On the earlier run, that meant 4 hosts. |
