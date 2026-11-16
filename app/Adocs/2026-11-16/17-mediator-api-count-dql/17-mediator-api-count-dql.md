# Mediator API Count DQL

```
API count by host
  last 60 minutes
  one file: apigw5590/server.log
  four hosts
        |
        v
API text sits later in the line
  visible text is "API: "
  the words "API Version" are not in that spot
        |
        v
read the word after "API: "
count by API and host.name
        |
        v
ALL is a second count
  same API, every host together
```

| What you asked for | What to paste |
|---|---|
| Splunk chart `Count of API` by `API` and `host` | The first query. |
| The `ALL` column | The second query. |
| Proof the four hosts are present | The third query. It does not read `API`. |

## Summary

This dashboard panel counts mediator log lines by API name and host. The file is `/opt/softwareag/log/1015/apigw5590/server.log`. The time picker is the last 60 minutes. Read the API name as the word after `API: `, then count.

## Investigation

The open search is:

```
(index=* OR index=_*) (index=eip1015 sourcetype=eip_mediator_serverlog)
```

The panel search adds the chart. It renames `API` to `RootObject.API`, appends a fake host `----`, and renames that column to `ALL`. `limit=101` keeps up to 101 API names. The field list on this search shows 34 API names, so that limit does not drop a name.

The dashboard URL uses `earliest=-60m@m` and `latest=now`. That is the last 60 minutes, snapped to the minute.

The source popup has one value:

| Field | Value | Count on the popup |
|---|---|---|
| `source` | `/opt/softwareag/log/1015/apigw5590/server.log` | 125,733 |

The host popup has four values. Those four counts add up to 125,733.

| Host | Count on the popup |
|---|---|
| `WPALJA21BC.prprivmgmt.intraxa` | 32,913 |
| `WPALJA21C0.prprivmgmt.intraxa` | 31,448 |
| `WPALJA21B9.prprivmgmt.intraxa` | 30,971 |
| `WPALJA21BF.prprivmgmt.intraxa` | 30,401 |

The Events tab on the same paused search says 113,154. Keep that number separate from the field popup. Do not add the two numbers together.

A visible line starts like this:

```
2026-11-16 14:32:55.045 JST [YAI.0102.0011] (tid=60435) [default][WPALJA21C0.prprivmgmt...
```

The same event view shows `API: pol` later in the text. The earlier notebook parse looked for `API: ` and then the words `API Version`. That pattern returned 0 rows. The start of the line is the timestamp and `[YAI....]`. The API name is farther along.

`(index=* OR index=_*)` does not add logs outside `eip1015`, because the next term requires `index=eip1015`. In Dynatrace the matching field already proved for this file is `log.source`. The host column already proved is `host.name`.

## Result

Count of API by API and host. Set the notebook time picker to Last 60 minutes as well.

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "LD 'API: ' LD:API ' '"
| filter isNotNull(API)
| summarize `Count of API` = count(), by: { API, host.name }
| sort `Count of API` desc
```

The `ALL` column is the same API counted across every host:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "LD 'API: ' LD:API ' '"
| filter isNotNull(API)
| summarize ALL = count(), by: { API }
| sort ALL desc
```

Host check. This one should return the four names even when the API parse is still short:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| summarize eventCount = count(), by: { host.name }
| sort eventCount desc
```

If the API column is empty, or the name stops at `pol`, run this and keep one full `content` line:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    and contains(content, "API:", caseSensitive:false)
| fields timestamp, host.name, content
| limit 3
```

The word after `API:` has to be copied from that full line. A partial `pol` is not enough to name the API.

## Data flow map

```
apigw5590/server.log
  four hosts
        |
        v
content
  "API: " then the API name
        |
        +--> count by API and host.name
        |
        +--> count by API
               this is the ALL column
```

## Related files

| File | Purpose |
|---|---|
| `17-mediator-api-count-dql.dql` | The chart query, the ALL query, and the host check. |
| `0-pic.md` | From the file to the two counts. |
| `1-investigation.md` | The Splunk counts on this screen. |
| `2-result.md` | The queries to paste. |
| `3-glossary.md` | The words. |
| `17-mediator-api-count-dql-follow.txt` | The same steps for a phone. |
| `17.sh` | Copy commands. |

Commands: [17.sh](17.sh)
