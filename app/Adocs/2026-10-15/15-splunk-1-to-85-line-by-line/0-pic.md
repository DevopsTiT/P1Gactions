# Splunk 1 To 85 Pic

```
Any Splunk line
 1. source? index= / sourcetype= / host= / metadata / makeresults
 2. text? bare word (whole word, any case) | "phrase" (any case) | match/regex/CASE (exact case) | field=value
 3. pipes? rex, spath, eval → dedup, where, search → stats, timechart → table, sort
 4. [subsearch]? runs first, feeds IDs
 unknown text → placeholder
```

```
Splunk: source → text → pipes → (subsearch) → rows
DQL:    fetch logs → src filter → contains / matchesPhrase / parse → summarize / lookup → fields
```
