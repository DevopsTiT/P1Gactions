# Mediator Path And Four Hosts

```
sourcetype eip_mediator_serverlog
  source popup is one file
  /opt/softwareag/log/1015/apigw5590/server.log
  host popup is four gateways
  B9, BF, C0, BC
        |
        v
DQL filters that file path
  reads API: from the line
  counts by API and by host
  second query is the ALL total
```

| What the screen shows | Value |
|---|---|
| Search | `index=eip1015` and `sourcetype=eip_mediator_serverlog` |
| Source file | `/opt/softwareag/log/1015/apigw5590/server.log` |
| Hosts | `WPALJA21B9`, `WPALJA21BF`, `WPALJA21C0`, `WPALJA21BC` |
| API field | 41 values on the field list |
| Events tab on the host screen | 998,376 |

## Summary

Use the file path from the source popup. The host popup lists four gateways. The count is still one row per API and host, and a second query for the total per API.

## Investigation

The search is the base of the API chart:

```
(index=* OR index=_*) (index=eip1015 sourcetype=eip_mediator_serverlog)
```

The source popup has one value:

```
/opt/softwareag/log/1015/apigw5590/server.log
```

The host popup has four values, each about a quarter of the events:

| Host | Count on the popup |
|---|---|
| `WPALJA21B9.prprivmgmt.intraxa` | 261,299 |
| `WPALJA21BF.prprivmgmt.intraxa` | 251,888 |
| `WPALJA21C0.prprivmgmt.intraxa` | 249,045 |
| `WPALJA21BC.prprivmgmt.intraxa` | 248,662 |

An opened line is host `WPALJA21BF` and the same `apigw5590` file. The line starts with the host name inside brackets. The API name is the text `API: <name> API Version`.

The events tab on the host screenshot reads 998,376. The source screenshot was taken on an earlier view of the job. Set the notebook picker to the same range as the Splunk job before comparing counts.

## Result

Set the notebook time picker to the Splunk job range. Paste:

```
fetch logs
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "LD 'API: ' LD:API ' API Version'"
| parse content, "LD '][' LD:gatewayHost ']'"
| filter isNotNull(API)
| summarize CountOfAPI = count(), by: { API, gatewayHost }
| sort CountOfAPI desc
```

`gatewayHost` is the name inside the second pair of brackets. The four names on the popup are the hosts you should see.

The total per API, the `ALL` column:

```
fetch logs
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "LD 'API: ' LD:API ' API Version'"
| filter isNotNull(API)
| summarize CountOfAPI = count(), by: { API }
| sort CountOfAPI desc
```

When the first query returns 0 records, the file path is in another field. Run:

```
fetch logs
| filter contains(content, "apigw5590/server.log", caseSensitive:false)
    or contains(log.source, "apigw5590/server.log", caseSensitive:false)
| fields timestamp, host.name, log.source, content
| limit 5
```

Use the field that contains `apigw5590/server.log` in place of `log.source`.

## Data flow map

```
/opt/softwareag/log/1015/apigw5590/server.log
  B9
  BF
  C0
  BC
        |
        v
API name from the line
        |
        v
CountOfAPI by API and host
        |
        v
second query
  CountOfAPI by API
  the ALL column
```

## Related files

| File | Purpose |
|---|---|
| `12-mediator-path-four-hosts.dql` | The count, the total, and the check. |
| `0-pic.md` | From the file path to the counts. |
| `1-investigation.md` | The source value and the four hosts. |
| `2-result.md` | The queries to paste. |
| `3-glossary.md` | The words. |
| `12-mediator-path-four-hosts-follow.txt` | The same steps for a phone. |
| `12.sh` | Copy commands. |

Commands: [12.sh](12.sh)
