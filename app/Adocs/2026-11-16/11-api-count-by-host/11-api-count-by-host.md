# API Count By Host

```
mediator server logs
  index eip1015
  sourcetype eip_mediator_serverlog
        |
        v
count events by API and by host
  the ---- host column is the total
  Splunk renames that column to ALL
        |
        v
DQL
  one row per API and host
  a second query for the total per API
```

| Splunk piece | What it does |
|---|---|
| `index=eip1015 sourcetype=eip_mediator_serverlog` | Keeps the mediator server logs. |
| `index=* OR index=_*` | Does not add logs. The next term already requires `eip1015`. |
| `chart count by API host` | Counts events for each API on each host. |
| `host=mvappend(host,"----")` | Adds a fake host so the chart also builds a total. |
| `rename *----* AS *ALL*` | Names that total column `ALL`. |
| `limit=101` | Splunk keeps 101 host columns and folds the rest into OTHER. |
| Shared time picker | The dashboard chooses the window. |

## Summary

The panel counts mediator log events for each API, split by host, and adds a total column named `ALL`. DQL returns the same numbers as rows: one row per API and host, plus a second query that is the total per API.

## Investigation

The search box builds a wide chart. Each event is copied once for its real host and once for a placeholder host `----`. The chart counts `API` by that host value. The placeholder column is then renamed to `ALL`.

The filters that choose the logs are `index=eip1015` and `sourcetype=eip_mediator_serverlog`. The `index=*` term does not widen that set.

`API` is a Splunk field. On mediator lines the text looks like `API: <name> API Version`. The query below reads the name from that text. Set the notebook time picker to the same range as the dashboard.

## Result

Count per API and host:

```
fetch logs
| filter contains(content, "API:", caseSensitive:false)
| parse content, "LD 'API: ' LD:API ' API Version'"
| filter isNotNull(API)
| summarize CountOfAPI = count(), by: { API, host.name }
| sort CountOfAPI desc
```

The total column, which Splunk calls `ALL`:

```
fetch logs
| filter contains(content, "API:", caseSensitive:false)
| parse content, "LD 'API: ' LD:API ' API Version'"
| filter isNotNull(API)
| summarize CountOfAPI = count(), by: { API }
| sort CountOfAPI desc
```

When a column named `API` already exists, use that column and skip the parse:

```
fetch logs
| filter isNotNull(API)
| summarize CountOfAPI = count(), by: { API, host }
| sort CountOfAPI desc
```

Splunk stops at 101 host columns. These queries list every API and host pair in the picker window.

## Data flow map

```
eip_mediator_serverlog
  line has API: name
        |
        v
count by API and host
        |
        v
CountOfAPI
        |
        +-- second query, count by API only
              the ALL column
```

## Related files

| File | Purpose |
|---|---|
| `11-api-count-by-host.dql` | The by-host count and the total. |
| `0-pic.md` | From the chart to two DQL queries. |
| `1-investigation.md` | What the Splunk chart is doing. |
| `2-result.md` | The queries to paste. |
| `3-glossary.md` | The words. |
| `11-api-count-by-host-follow.txt` | The same steps for a phone. |
| `11.sh` | Copy commands. |

Commands: [11.sh](11.sh)
