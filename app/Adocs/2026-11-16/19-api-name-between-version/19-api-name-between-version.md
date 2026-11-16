# API Name Between Version

```
apiSnippet shows the shape
  API: <name> API Version: 1.0
        |
        v
path check shows one file
  /opt/softwareag/log/1015/apigw5590/server.log
  470,865 lines in that hour
        |
        v
read the name between
  "API: " and " API Version"
        |
        v
count by API and host.name
ALL is the count by API
```

| Piece of the line | Example from the notebook |
|---|---|
| Text before the name | `API:` |
| API name | `policy-management-V1` |
| Text after the name | `API Version: 1.0` |
| File | `/opt/softwareag/log/1015/apigw5590/server.log` |
| Lines in that hour | 470,865 |

## Summary

The short snippet shows where the API name sits. Read the words between `API: ` and ` API Version`, then count those names by host. That is the Splunk chart.

## Investigation

Five rows came back at 14:47:55. The window is 13:47:55 to 14:47:55. Every row is host `WPALJA21BC.prprivmgmt.intraxa`.

| API name on the screen | What follows the name |
|---|---|
| `jp-Designing-DesignProduct-CalculatePremiumReserveCashValue-v1-vs` | `API Version: 1.0` |
| `jp-Distributing-Sell-GenerateFormImage-v2-vs` | `API Version: 1.0` |
| `jp-Distributing-Sell-XUPdateLeadSalesActivityInfo-v2-vs` | `API Version: 1.0` |
| `policy-management-V1` | `API Version: 1.0` |
| `technical-utility-V1` | `API Version: 1.0` |

The path query returned one row. `log.source` is exactly `/opt/softwareag/log/1015/apigw5590/server.log`. The count is 470,865 for 13:48:52 to 14:48:52.

The Splunk host popup for this file added up to 125,733, and that search was paused. Dynatrace has more lines for the same path in its own hour. The chart below counts the Dynatrace lines.

## Result

Count of API by API and host:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "LD 'API: ' LD:API ' API Version'"
| filter isNotNull(API)
| summarize `Count of API` = count(), by: { API, host.name }
| sort `Count of API` desc
```

The `ALL` column:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "LD 'API: ' LD:API ' API Version'"
| filter isNotNull(API)
| summarize ALL = count(), by: { API }
| sort ALL desc
```

A line is kept when it contains `API: ` and then the words `API Version`. The five sample rows have that shape. Splunk listed 34 API names on its field list. This hour in Dynatrace can show a different set, because it is a later window and a larger set of lines.

## Data flow map

```
one file
  470,865 lines
        |
        v
API: <name> API Version: 1.0
        |
        +--> count by API and host.name
        |
        +--> count by API
               this is ALL
```

## Related files

| File | Purpose |
|---|---|
| `19-api-name-between-version.dql` | The chart query and the ALL query. |
| `0-pic.md` | From the snippet to the count. |
| `1-investigation.md` | The five names and the one file path. |
| `2-result.md` | The queries to paste. |
| `3-glossary.md` | The words. |
| `19-api-name-between-version-follow.txt` | The same steps for a phone. |
| `19.sh` | Copy commands. |

Commands: [19.sh](19.sh)
