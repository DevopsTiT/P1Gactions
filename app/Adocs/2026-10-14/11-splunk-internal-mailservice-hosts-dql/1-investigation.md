# Splunk Internal Mailservice Hosts Investigation

| What was checked | Finding |
|---|---|
| #14 data source | Splunk `_internal` license log. Not in Dynatrace. |
| #14 rebuild | Log text size per day. Close to ingest volume, not exact billing. |
| #14 `pool` field | No Dynatrace equivalent. Dropped. |
| #15 and #16 `index` | No Dynatrace index. Use host, namespace, or bucket filter. |
| #16 meaning | Tomcat writes "Server startup" when it finishes starting. Shows restarts. |
| #17 data source | Splunk `_internal` metrics log. Rebuilt as line count per source. |
| #18 data source | Splunk host metadata. Rebuilt as last log time per host. |
| #18 cost | Scanning 7 days of all prod logs is heavy. Shorten if needed. |
