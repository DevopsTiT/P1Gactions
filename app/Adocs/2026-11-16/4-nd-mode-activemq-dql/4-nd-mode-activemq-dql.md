# ND Mode ActiveMQ DQL

```
Splunk search
  index eip1015
  sourcetype eip_nd_mode
  host wpalja307b.prprivmgmt.intraxa
  head 1
  table ACTIVEMQMODE
        |
        v
newest line only
  source ND_Mode_DC1 on every row
  line text ACTIVEMQMODE="..."
        |
        v
DQL
  log.source contains ND_Mode_DC1
  host wpalja307b
  parse ACTIVEMQMODE
  sort newest first
  limit 1
```

| What Splunk showed | Value |
|---|---|
| Search result of `head 1` | One row. `ACTIVEMQMODE` is `A`. |
| Full search | 1,486 events from 15 Nov 09:00 through 16 Nov 09:45. |
| Host | `wpalja307b.prprivmgmt.intraxa` on every row. |
| Source | `ND_Mode_DC1` on every row. |
| Line text | `MFSUBENV="ND", ACTIVEMQMODE="A"` on the opened rows. |

## Summary

`head 1` keeps the newest event. `table ACTIVEMQMODE` shows only that field. In this job the newest value is `A`. The DQL reads source `ND_Mode_DC1` for host `wpalja307b`, pulls `ACTIVEMQMODE` out of the line, and keeps the newest row.

## Investigation

The search that produced the single value is:

```
index=eip1015 sourcetype=eip_nd_mode host="wpalja307b.prprivmgmt.intraxa"
| head 1
| table ACTIVEMQMODE
```

The statistics tab shows `ACTIVEMQMODE` = `A`.

The wider search, without `head 1`, returned 1,486 events from 2026-11-15 09:00 through 2026-11-16 09:45. The host popup is only `wpalja307b.prprivmgmt.intraxa`. The source popup is only `ND_Mode_DC1`. Opened lines look like:

```
MFSUBENV="ND", ACTIVEMQMODE="A"
```

The field list shows two different `ACTIVEMQMODE` values in that window. `head 1` does not count them. It returns whichever value is on the newest line. In this job that value is `A`.

`ND_Mode_DC1` is the Splunk source name. Dynatrace stores that kind of name in `log.source`.

## Result

Set the notebook time picker to about the last 24 hours, or use the `from:` already on the query. Paste:

```
fetch logs, from: now()-24h
| filter contains(log.source, "ND_Mode_DC1", caseSensitive:false)
    and (
      contains(host.name, "wpalja307b", caseSensitive:false)
      or contains(content, "wpalja307b.prprivmgmt.intraxa", caseSensitive:false)
    )
| parse content, "LD 'ACTIVEMQMODE=\"' LD:ACTIVEMQMODE '\"'"
| filter isNotNull(ACTIVEMQMODE)
| sort timestamp desc
| limit 1
| fields timestamp, ACTIVEMQMODE
```

`ACTIVEMQMODE` on that one row is the same cell Splunk put in the table. For this job, expect `A`.

To see both values in the window:

```
fetch logs, from: now()-24h
| filter contains(log.source, "ND_Mode_DC1", caseSensitive:false)
    and (
      contains(host.name, "wpalja307b", caseSensitive:false)
      or contains(content, "wpalja307b.prprivmgmt.intraxa", caseSensitive:false)
    )
| parse content, "LD 'ACTIVEMQMODE=\"' LD:ACTIVEMQMODE '\"'"
| filter isNotNull(ACTIVEMQMODE)
| summarize eventCount = count(), by: { ACTIVEMQMODE }
```

When the first query returns 0 records, run:

```
fetch logs, from: now()-24h
| filter contains(content, "ACTIVEMQMODE", caseSensitive:false)
| fields timestamp, host.name, log.source, content
| limit 5
```

Use the field that contains `ND_Mode_DC1` in place of `log.source`.

## Data flow map

```
source ND_Mode_DC1
  host wpalja307b.prprivmgmt.intraxa
  line ACTIVEMQMODE="A"
        |
        v
1,486 events in the long window
        |
        v
newest event only
        |
        v
ACTIVEMQMODE
```

## Related files

| File | Purpose |
|---|---|
| `4-nd-mode-activemq-dql.dql` | The newest-value query, the count by mode, and the check. |
| `0-pic.md` | From the Splunk table to one DQL row. |
| `1-investigation.md` | Host, source, and the line text. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `4-nd-mode-activemq-dql-follow.txt` | The same steps for a phone. |
| `4.sh` | Copy commands. |

Commands: [4.sh](4.sh)
