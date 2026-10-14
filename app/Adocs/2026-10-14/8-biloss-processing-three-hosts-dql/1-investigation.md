# BILoss Processing Three Hosts DQL Investigation

| Splunk stage | DQL step |
|---|---|
| 3 hosts with OR | in(lower(host.name), array(3 lowercase names)) |
| search (7 phrases) | 7 contains, caseSensitive:false |
| mvappend(if(match(...))) x7 | arrayRemoveNulls(array(if(contains(...)))) |
| strftime | formatTimestamp, Asia/Tokyo |
| table | fields time, host.name, matched_keywords, content |
