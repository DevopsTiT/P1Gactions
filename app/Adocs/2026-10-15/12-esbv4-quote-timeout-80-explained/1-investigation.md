# ESBv4 Quote Timeout 80 Investigation

| What was checked | Finding |
|---|---|
| Splunk #80 shape | Same as #77 to #79. Only the channel is kakakucomauto. |
| Subsearch field name | `query`, which Splunk's `format` writes as plain search words. |
| ID format | UUID, 8-4-4-4-12 lowercase hex. |
| DQL source | 2026-10-15 answer 1, file `-80-kakakucomauto.dql`. |
| Difference | Splunk matches the ID anywhere in the text. DQL parses the ID on both sides and joins exactly. |
