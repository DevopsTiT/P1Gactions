# Transform 41 BC2 CVS Offline Duplicates

```
bc2-batch + Quick record for CVS Offline?
 → keep those lines (caseSensitive:false)
 → dedup content
 → parse Identifier, Amount, PaymentDate
 → summarize count by those three
 → keep count > 1  (duplicates)
 → sort by PaymentDate
 → fields Identifier, Amount, PaymentDate
```

| Key point | Detail |
|---|---|
| What this is | Find duplicate CVS Offline quick payment records |
| Why it matters | Same Identifier/Amount/PaymentDate appearing more than once |
| Index | `bc2-batch*` → pod/host starts with `bc2-batch` |

## Summary

Splunk **41** dedups raw lines, groups by Identifier / Amount / PaymentDate, and keeps groups with count &gt; 1. DQL does the same with `dedup content`, parse, and `summarize`.

## Splunk (source)

```
index=bc2-batch* "PaymentRecordType=Quick record for CVS Offline"
| dedup _raw
| stats count by Identifier, Amount, PaymentDate
| where count > 1
| eval PaymentDateForSort=strptime(PaymentDate, "%a %b %d %H:%M:%S %Z %Y")
| sort PaymentDateForSort
| fields Identifier, Amount, PaymentDate
```

## DQL (live)

```
fetch logs, from:now()-7d
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2-batch")
    or contains(log.source, "bc2-batch", caseSensitive:false)
    or contains(k8s.pod.name, "bc2-batch", caseSensitive:false)
| filter contains(content, "PaymentRecordType=Quick record for CVS Offline", caseSensitive:false)
| dedup content
| parse content, "LD 'Identifier=' LD:Identifier ','"
| parse content, "LD 'Amount=' LD:Amount ','"
| parse content, "LD 'PaymentDate=' LD:PaymentDate ','"
| summarize count = count(), by:{ Identifier, Amount, PaymentDate }
| filter count > 1
| fieldsAdd pd_clean = replaceString(PaymentDate, " JST ", " ")
| parse pd_clean, "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):PaymentDateForSort"
| sort PaymentDateForSort asc
| fields Identifier, Amount, PaymentDate
```

## Verify dummy (two rows → count &gt; 1)

```
fetch logs
| limit 2
| fieldsAdd content = "2026-10-14 02:10:05,120 INFO [CvsImport-1] PaymentRecordType=Quick record for CVS Offline, Identifier=CVS-000731, Amount=12800, PaymentDate=Wed Oct 14 10:00:00 JST 2026, RunID=R-0101"
| fields content
| filter contains(content, "PaymentRecordType=Quick record for CVS Offline", caseSensitive:false)
| parse content, "LD 'Identifier=' LD:Identifier ','"
| parse content, "LD 'Amount=' LD:Amount ','"
| parse content, "LD 'PaymentDate=' LD:PaymentDate ','"
| summarize count = count(), by:{ Identifier, Amount, PaymentDate }
| filter count > 1
| fields Identifier, Amount, PaymentDate, count
```

**Pass:** one group, `Identifier=CVS-000731`, `count=2`.

## Splunk → DQL

| Splunk | DQL |
|---|---|
| `index=bc2-batch*` | `startsWith(src, "bc2-batch")` + contains on pod/source |
| `dedup _raw` | `dedup content` |
| `stats count by Identifier, Amount, PaymentDate` | parse fields + `summarize count(), by:{...}` |
| `where count > 1` | `filter count > 1` |
| `strptime(... JST ...)` | strip ` JST `, parse TIMESTAMP, sort |

## Data flow map

```
bc2-batch logs
  → PaymentRecordType=Quick record for CVS Offline
  → dedup content
  → cut Identifier / Amount / PaymentDate
  → count by those three
  → keep count > 1
  → sort by payment date → fields
```

## Related files

| File | Role |
|---|---|
| `4-transform-41-bc2-cvs-offline-duplicates.dql` | Live + verify |
| `4.sh` | Dual-write |

## Commands

See [4.sh](4.sh).
