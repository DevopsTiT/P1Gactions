# Glossary

| Term | What it means | Why you care |
|---|---|---|
| DQL | Dynatrace Query Language, used in Notebooks | All three queries are DQL |
| Grail | Dynatrace's data store for logs, events and metrics | `fetch logs` reads from it |
| `log.source` | The file path or log name a line came from | The field we compare with pic2 |
| `dt.entity.host_group` | ID of the host group the host belongs to | Scopes the check to one group |
| Host group | A set of hosts configured together in OneAgent | Windows and Linux servers are usually in different groups |
| `in(value, array(...))` | True when the value is in the list | The membership check |
| `startsWith`, `endsWith` | Text begins or ends with a given string | Used to fold rotated files into one wildcard pattern |
| `append [data record(...)]` | Adds hand-written rows to the result | Makes zero-log paths appear as MISSING |
| `collectDistinct` | Unique list of values in a group | Shows the real file names behind a wildcard |
| Log ingest rule | Dynatrace setting deciding which files OneAgent sends | Most common reason a file is MISSING |
| OneAgent | Dynatrace agent on the host | Reads the log files |
