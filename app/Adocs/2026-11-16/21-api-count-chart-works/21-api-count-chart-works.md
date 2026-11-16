# API Count Chart Works

```
five-row check
  API name is clean
  policy-management-V1
        |
        v
count by API and host
  146 rows
  four hosts
        |
        v
ALL
  38 API names
  top name is customer-info-V2
```

| Result | What it means |
|---|---|
| Five sample rows show a clean API name | The parse now reaches `API Version`. |
| 146 rows by API and host | Each row is one API on one gateway. |
| 38 rows in `ALL` | Thirty-eight different API names in this hour. |
| Top `ALL` value is 26,991 | `customer-info-V2` is the busiest API in this hour. |

## Summary

The Splunk chart shape is now in Dynatrace. One query counts each API on each host. The other counts that API across every host. The window is 13:55 to 14:55.

## Investigation

The five-row check ran at 14:55:11. All five rows are `WPALJA21BF.prprivmgmt.intraxa`, because those were the newest lines. The names are `policy-management-V1` and `jp-MarketAccess-DistributionManagement-Commission-v3-vs`.

The host chart ran at 14:55:46. The window is 13:55:45 to 14:55:45. It returned 146 records. These are the top rows that are fully readable:

| API | Host | Count of API |
|---|---|---|
| `customer-info-V2` | `WPALJA21BC.prprivmgmt.intraxa` | 6,974 |
| `customer-info-V2` | `WPALJA21B9.prprivmgmt.intraxa` | 6,734 |
| `customer-info-V2` | `WPALJA21BF.prprivmgmt.intraxa` | 6,716 |
| `customer-info-V2` | `WPALJA21C0.prprivmgmt.intraxa` | 6,637 |
| `policy-management-V1` | `WPALJA21BF.prprivmgmt.intraxa` | 4,875 |
| `policy-management-V1` | `WPALJA21BC.prprivmgmt.intraxa` | 4,851 |
| `policy-management-V1` | `WPALJA21B9.prprivmgmt.intraxa` | 4,596 |

Longer names are cut off in the grid with `...`. Two cut-off names can look the same even when the full name is different. Widen that column to read the rest.

The `ALL` query ran at 14:55:57. The window is 13:55:57 to 14:55:57. It returned 38 records. The visible top is:

| API | ALL |
|---|---|
| `customer-info-V2` | 26,991 |
| `policy-management-V1` | 18,636 |
| `jp-Designing-DesignProduct-CalculatePremiumReserveCashValue-v1-vs` | 15,448 |
| `customer-info-V1` | 13,512 |
| `jp-MarketAccess-DistributionManagement-Commission-v3-vs` | 6,191 |
| `jp-Distributing-Sell-GenerateFormImage-v2-vs` | 4,394 |
| `jp-MarketAccess-DistributionManagement-Commission-v4-vs` | 3,637 |
| `technical-utility-V1` | 3,018 |
| `jp-CoreBusiness-ServiceManagement-ICMCase-v1-vs` | 1,499 |
| `jp-MarketAccess-InteractionManagement-RequestService-v1-vs` | 1,226 |
| `is-CoreBusiness-ServiceManagement-ClaimService-v1-vs` | 1,086 |

The four `customer-info-V2` host counts add up to 27,061. The `ALL` value is 26,991. The `ALL` query started 12 seconds later, so the hour slid forward and the two totals are not the same run.

Splunk’s field list showed 34 API names on a paused search. This hour in Dynatrace has 38. Those are different windows.

This chart counts lines that contain `API Version`. The file itself had about 470,865 lines in an earlier hour. Lines without those words stay out of this chart.

## Result

Keep these two queries. They are the panel.

Count by API and host:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'"
| filter isNotNull(API)
| summarize `Count of API` = count(), by: { API, host.name }
| sort `Count of API` desc
```

`ALL`:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'"
| filter isNotNull(API)
| summarize ALL = count(), by: { API }
| sort ALL desc
```

## Data flow map

```
apigw5590/server.log
  last 60 minutes
        |
        v
API: <name> API Version
        |
        +--> 146 rows
        |      API + host + count
        |
        +--> 38 rows
               API + ALL
```

## Related files

| File | Purpose |
|---|---|
| `21-api-count-chart-works.dql` | The two queries that produced these tables. |
| `0-pic.md` | From the line to the two tables. |
| `1-investigation.md` | The counts visible on the screen. |
| `2-result.md` | What to keep. |
| `3-glossary.md` | The words. |
| `21-api-count-chart-works-follow.txt` | The same steps for a phone. |
| `21.sh` | Copy commands. |

Commands: [21.sh](21.sh)
