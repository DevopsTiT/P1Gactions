# BILoss Retrieve Files CMX Error Investigation

| What was checked | Finding |
|---|---|
| Splunk #7 | `host="BILoss-retrieve-files-cmx-prod" | search "CMX Error" | regex _raw="CMX Error" | eval time=strftime(...) | table time host _raw` |
| Case handling | `regex` makes the match case-sensitive. |
| Host pattern | Same style as the 2026-10-14 #9 BILoss query, which used `lower(host.name) ==`. |
