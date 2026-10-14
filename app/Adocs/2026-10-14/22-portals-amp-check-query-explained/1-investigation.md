# Portals AMP Check Query Investigation

| Line | Finding |
|---|---|
| 1 | 24-hour window. |
| 2 to 5 | Four name fields, case ignored, joined with OR. |
| 6 | Groups by host, pod, namespace, source, ingest path. |
| Result | 0 records, 171.29 GiB scanned. |
| Note | This is DQL. The Splunk #85 query is in answer 20. |
