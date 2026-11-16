# API Parse Dropped The Rows

```
log.source path matches
  the check returned 5 records
  host.name is WPALJA21BC.prprivmgmt.intraxa
        |
        v
parse looks for API: name API Version
  that text is not in the visible line
  API stays empty
        |
        v
isNotNull(API) drops every row
  count is 0
        |
        v
count by host.name first
  then print lines that contain API
```

| Query | Result |
|---|---|
| Count by API and host | 0 records. Last 1 hour. |
| Count by API | 0 records. Last 1 hour. |
| Path in `content` or `log.source` | 5 records. `log.source` is the `apigw5590` file. |

## Summary

The path filter works. `host.name` is already the gateway name. The count is 0 because the parse did not find the words `API:` and `API Version`, so `isNotNull(API)` removed every row.

## Investigation

Both count queries filter:

```
contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
```

Then they parse `API:` up to `API Version` and keep only rows where `API` is filled.

The check query uses the same path and returns 5 records at 13:19:44. On those rows:

| Column | Value |
|---|---|
| `host.name` | `WPALJA21BC.prprivmgmt.intraxa` |
| `log.source` | `/opt/softwareag/log/1015/apigw5590/server.log` |
| Start of `content` | `2026-11-16 13:19:44.128 JST [YAI.0103.0074I] (tid=23899) [default][W` |

The visible start of the line has the host in brackets. It does not show `API:`. The parse leaves `API` empty. `isNotNull(API)` then deletes the row. A deleted row cannot be counted.

The notebook window is Last 1 hour, 12:19 to 13:19. The 5 records are inside that hour, so the empty count is not an empty hour.

## Result

Count the rows that are already there, by the host column:

```
fetch logs, from: now()-1h
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| summarize eventCount = count(), by: { host.name }
| sort eventCount desc
```

Print three lines that contain the letters API, so the real spelling can be read:

```
fetch logs, from: now()-1h
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    and contains(content, "API", caseSensitive:false)
| fields timestamp, host.name, content
| limit 3
```

| What comes back | Next step |
|---|---|
| The host count has rows, and the three lines show `API:` | Send one full line. The parse can be matched to that spelling. |
| The host count has rows, and the API query is 0 | The word API is not in the line. Splunk extracted it into a field that is not in `content`. |
| The host count is 0 | The picker is outside the minutes that have this file. The check rows were at 13:19. |

## Data flow map

```
apigw5590/server.log
  5 rows in the check
  host.name filled
        |
        v
parse API: ... API Version
  no match
        |
        v
isNotNull(API)
  drops the rows
        |
        v
0 records
```

## Related files

| File | Purpose |
|---|---|
| `13-api-parse-dropped-rows.dql` | The host count and the three-line sample. |
| `0-pic.md` | Why the count is empty. |
| `1-investigation.md` | What the three screenshots show. |
| `2-result.md` | The queries to run next. |
| `3-glossary.md` | The words. |
| `13-api-parse-dropped-rows-follow.txt` | The same steps for a phone. |
| `13.sh` | Copy commands. |

Commands: [13.sh](13.sh)
