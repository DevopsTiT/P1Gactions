# Splunk To DQL Patterns Pic

## Decision tree

```
host= / index= / sourcetype= + words   → A: source + text
mvappend(if(match...))                 → B: keyword tags
replace | spath | message.url          → C: JSON fields
rex / key=value + stats / dedup        → D: extract and count
[ subsearch ]                          → E: lookup on ID
metadata / _internal / lookup table    → F: rebuild (Splunk-only data)
strptime + relative_time               → G: date math
0 rows → check query → not found → onboarding request
```

## Data flow

```
SPL -> pattern -> source filter -> text filter -> shape -> result
```
