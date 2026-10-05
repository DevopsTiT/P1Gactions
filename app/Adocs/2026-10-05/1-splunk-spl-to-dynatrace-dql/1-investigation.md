# Investigation

| What was checked | Finding |
|---|---|
| The SPL being converted | The three source-check queries from `2026-10-02/1-splunk-simple-source-check` |
| Index equivalent | Grail stores logs in buckets (`dt.system.bucket`); some setups copy the Splunk index into a custom attribute instead |
| Source equivalent | `log.source` is the usual field; network syslog may use `host.name` or `syslog.hostname` |
| tstats equivalent | None; DQL scans records, so time range and bucket filter matter for cost and speed |
| Screenshot | A Davis problem event for TS12, not network syslog |
