# BILoss Retrieve Files CMX DQL Investigation

| Splunk stage | DQL step |
|---|---|
| host="BILoss-retrieve-files-cmx-prod" | lower(host.name) == "biloss-retrieve-files-cmx-prod" |
| search (7 phrases) | 7 contains, caseSensitive:false |
| mvappend(if(match(...))) x7 | arrayRemoveNulls(array(if(contains(...)))) |
| strftime | formatTimestamp, Asia/Tokyo |
| table | fields time, host.name, matched_keywords, content |
