# BILoss CMX Error DQL Investigation

| Splunk stage | DQL step |
|---|---|
| host="BILoss-retrieve-files-cmx-prod" | lower(host.name) == "biloss-retrieve-files-cmx-prod" |
| search "CMX Error" + regex _raw="CMX Error" | contains(content, "CMX Error"), case sensitive |
| strftime | formatTimestamp, Asia/Tokyo |
| table time host _raw | fields time, host.name, content |
