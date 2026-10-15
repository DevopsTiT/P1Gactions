# Splunk To DQL Pic

```
Splunk query → label: time | where | text | extract | shape | join
 time    → fetch logs, from:
 where   → src startsWith / host.name == / log.source
 text    → bare word: matchesPhrase | quoted: contains caseSensitive:false | CASE: contains
 extract → parse (rex, auto key=value) | parse JSON:j (spath) | fieldsAdd (eval)
 shape   → summarize | makeTimeseries | fields | sort | limit | dedup
 join    → lookup [ ] (subsearch) | load (lookup file) | max(timestamp) (metadata)
 test    → data record(...) → compare counts with Splunk
```
