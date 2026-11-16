# First ActiveMQ Mode A

```
content search found 290 rows
  some are sql-monitoring
  the mode is already a column
        |
        v
sql.activemqmode == "A"
sql.mfsubenv == "ND"
log.source == "sql-monitoring"
        |
        v
sort newest first
limit 1
        |
        v
one row
  sql.activemqmode = A
```

| What you see on the row | Field to use |
|---|---|
| The letter A | `sql.activemqmode` |
| ND | `sql.mfsubenv` |
| sql-monitoring | `log.source` |
| Newest of those rows | `sort timestamp desc` then `limit 1` |

## Summary

The value A is stored in `sql.activemqmode`. Filter that column to `A`, sort so the newest row is first, and keep one row. That is the first A.

## Investigation

The query on `log.source` containing `ND_Mode_DC1` returned no records. The follow-up search found 290 records whose text contains `ACTIVEMQMODE`.

The rows that carry the mode look like this:

```
{"MFSUBENV": "ND", "ACTIVEMQMODE": "A"}
```

On those rows Dynatrace has already split the text into columns:

| Column | Value on the screenshot |
|---|---|
| `log.source` | `sql-monitoring` |
| `sql.mfsubenv` | `ND` |
| `sql.activemqmode` | `A` |

Other rows in the 290 are Splunk internal logs. They mention the word and do not have this column set to A. Filtering `sql.activemqmode == "A"` leaves the mode records.

The host name on these Dynatrace rows is the ingest host. It is not the Splunk host `wpalja307b`.

## Result

Paste this. It returns the newest record whose mode is A.

```
fetch logs, from: now()-24h
| filter log.source == "sql-monitoring"
    and sql.activemqmode == "A"
    and sql.mfsubenv == "ND"
| sort timestamp desc
| limit 1
| fields timestamp, host.name, sql.mfsubenv, sql.activemqmode
```

The cell `sql.activemqmode` on that one row is the A from the Splunk table.

To list every A in the last 24 hours, remove `limit 1`.

## Data flow map

```
log line
  MFSUBENV ND
  ACTIVEMQMODE A
        |
        v
column sql.activemqmode
        |
        v
keep rows where the column is A
        |
        v
newest row
```

## Related files

| File | Purpose |
|---|---|
| `5-first-activemq-mode-a.dql` | The query that returns the newest A. |
| `0-pic.md` | From the column to one row. |
| `1-investigation.md` | Where A is stored. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `5-first-activemq-mode-a-follow.txt` | The same steps for a phone. |
| `5.sh` | Copy commands. |

Commands: [5.sh](5.sh)
