# Investigation

| Checked | Finding |
|---|---|
| Splunk rex | Level is read right after the timestamp, capitals only |
| eval upper | No effect on [A-Z]+ |
| Proposed filter | "ERROR " with caseSensitive:false matches "error " anywhere |
