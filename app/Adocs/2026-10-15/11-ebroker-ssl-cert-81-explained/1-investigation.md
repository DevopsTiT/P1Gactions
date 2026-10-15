# Ebroker SSL Cert 81 Investigation

| What was checked | Finding |
|---|---|
| 2026-10-14 answer 17 | #81 mapped as `lookup sslcert_lookup dest OUTPUT ssl_end_time` and `ssl_end_time < relative_time(now(), "+30d")`. |
| Target host | `ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa` |
| Data type | A lookup table, not logs. |
| Time format | Assumed Unix seconds. |
| Original screenshot | Not in notes. The Splunk text is rebuilt from the mapping. |
