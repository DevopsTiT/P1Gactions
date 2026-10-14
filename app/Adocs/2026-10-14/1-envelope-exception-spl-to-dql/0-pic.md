# Envelope Exception SPL To DQL Pic

## Decision tree

```
host filter → in(host.name, array(...))
search terms → contains(..., caseSensitive:false)
mvappend → arrayRemoveNulls(array(if(...)))
strftime → formatTimestamp
table → fields
empty? → check query → swap host filter
```

## Data flow

```
Grail logs → two hosts → Exception or ERROR → keywords list → JST time → table
```
