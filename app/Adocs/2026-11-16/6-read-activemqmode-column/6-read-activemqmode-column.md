# Read ActiveMQ Mode Column

```
query on sql.query_name dc1-nd-mode
  1 record
  content has ACTIVEMQMODE A
        |
        v
add the column sql.activemqmode
        |
        v
the cell shows A
```

| Piece on the screenshot | What to read |
|---|---|
| `sql.query_name` contains `dc1-nd-mode` | The filter that returned this 1 record. |
| `content` | `{"MFSUBENV": "ND", "ACTIVEMQMODE": "A"}` |
| Column to add | `sql.activemqmode` |
| Value | `A` |

## Summary

The record is already found. The letter A is in the field `sql.activemqmode`. Put that field in the `fields` line and the result cell shows A.

## Investigation

This query returned 1 record at 11/16/2026 9:55:24 AM:

```
fetch logs
| filter contains(sql.query_name, "dc1-nd-mode", caseSensitive:false)
```

`log.source` is `sql-monitoring`. The content is:

```
{"MFSUBENV": "ND", "ACTIVEMQMODE": "A"}
```

On these `sql-monitoring` rows Dynatrace stores `ND` in `sql.mfsubenv` and `A` in `sql.activemqmode`. The result table hid those columns because the query did not list them.

## Result

Paste this:

```
fetch logs
| filter contains(sql.query_name, "dc1-nd-mode", caseSensitive:false)
| fields timestamp, sql.mfsubenv, sql.activemqmode
| sort timestamp desc
| limit 1
```

The cell `sql.activemqmode` is A.

When that cell is empty, read A from the text instead:

```
fetch logs
| filter contains(sql.query_name, "dc1-nd-mode", caseSensitive:false)
| parse content, "LD 'ACTIVEMQMODE\", \"' LD:ACTIVEMQMODE '\"'"
| fields timestamp, ACTIVEMQMODE
| sort timestamp desc
| limit 1
```

## Data flow map

```
sql.query_name contains dc1-nd-mode
        |
        v
one sql-monitoring record
  content ACTIVEMQMODE A
        |
        v
field sql.activemqmode
        |
        v
cell A
```

## Related files

| File | Purpose |
|---|---|
| `6-read-activemqmode-column.dql` | The query that shows the A column. |
| `0-pic.md` | From the record to the cell. |
| `1-investigation.md` | The 1 record that was found. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `6-read-activemqmode-column-follow.txt` | The same steps for a phone. |
| `6.sh` | Copy commands. |

Commands: [6.sh](6.sh)
