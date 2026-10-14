# BC2 GMO Duplicate OrderID DQL Investigation

| Item | Value |
|---|---|
| Splunk search | index=bc2* Integration.GMO AND "Map returned by method call" AND "[acs=0&...&orderid=*&...&trandate=*]" \| dedup orderid \| rex 18/6/rest \| eval pattern \| stats count by pattern \| where count > 1 \| sort - count |
| Events in index | 849,714 |
| Hosts | bc2-ui-inssuite-prod-0, bc2-ui-inssuite-prod-1, bc2-batch-inssuite-prod-0, bc2-batch-inssuite-prod-1 |
| Source | s3://axa-gi-jp-logforwarders-prod/... |
| Unknown | Whether bc2 logs reach Dynatrace |
