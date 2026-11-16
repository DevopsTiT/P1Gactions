# Keep The Call Line Count

```
Splunk customer-info-V1
  2,776 + 3,524 + 3,885 + 5,267 = 15,452
        |
        v
add the 13,562 partner lines?
        |
        +--> about 27,000
        |      farther from Splunk
        |
        +--> keep the call line
               API: <name> API Version
               V2, policy, and the premium API already match
```

| API | Splunk, four hosts added | What Dynatrace should follow |
|---|---|---|
| `customer-info-V2` | 26,910 | The call line. The earlier Dynatrace hour was 26,991. |
| `policy-management-V1` | 18,637 | The call line. The earlier Dynatrace hour was 18,636. |
| Premium cash value API | 15,365 | The call line. The earlier Dynatrace hour was 15,448. |
| `customer-info-V1` | 15,452 | The call line. The partner sentence is a second line about that same call. |

## Summary

The partner sentence `Matching application found for the API:` is 13,562 lines for `customer-info-V1`. Splunk’s row is 15,452. Adding those lines makes about 27,000. The chart stays on the call line, `API: <name> API Version`.

## Investigation

This Splunk screen is Last 1 hour. The four host cells add up as follows.

| API | B9 | BC | BF | C0 | Sum |
|---|---|---|---|---|---|
| `customer-info-V2` | 6,548 | 6,902 | 6,810 | 6,650 | 26,910 |
| `policy-management-V1` | 4,656 | 4,718 | 4,811 | 4,452 | 18,637 |
| Premium cash value API | 3,805 | 3,836 | 3,876 | 3,848 | 15,365 |
| `customer-info-V1` | 2,776 | 3,524 | 3,885 | 5,267 | 15,452 |
| `jp-Distributing-Sell-GenerateFormImage-v2-vs` | 1,171 | 1,053 | 1,071 | 1,251 | 4,546 |

The Dynatrace split for `customer-info-V1`, from 14:13:46 to 15:13:46, was 13,797 call lines and 13,562 partner lines. 13,797 + 13,562 = 27,359.

The call line is the one that already sits next to Splunk for `customer-info-V2`, `policy-management-V1`, and the premium API.

## Result

Use this query. The filter drops the partner sentence. The parse keeps the call line.

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    and not(contains(content, "Matching application found for the API:", caseSensitive:false))
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'"
| filter isNotNull(API)
| summarize {
    `WPALJA21B9.prprivmgmt.intraxa` = countIf(host.name == "WPALJA21B9.prprivmgmt.intraxa"),
    `WPALJA21BC.prprivmgmt.intraxa` = countIf(host.name == "WPALJA21BC.prprivmgmt.intraxa"),
    `WPALJA21BF.prprivmgmt.intraxa` = countIf(host.name == "WPALJA21BF.prprivmgmt.intraxa"),
    `WPALJA21C0.prprivmgmt.intraxa` = countIf(host.name == "WPALJA21C0.prprivmgmt.intraxa"),
    ALL = count()
  }, by: { API }
| fields API, `WPALJA21B9.prprivmgmt.intraxa`, `WPALJA21BC.prprivmgmt.intraxa`, `WPALJA21BF.prprivmgmt.intraxa`, `WPALJA21C0.prprivmgmt.intraxa`, ALL
| sort API asc
```

`customer-info-V1` from this query will stay near the call-line count, 13,797 in the hour that ended at 15:13. Splunk’s row on this screen is 15,452. Those two hours are not the same minutes. The partner lines are not the missing 1,655, because adding them overshoots Splunk.

## Data flow map

```
one call
        |
        +--> API: customer-info-V1 API Version
        |      13,797
        |      this is the chart
        |
        +--> Matching application found for the API: customer-info-V1
               13,562
               left out
               Splunk row is 15,452
```

## Related files

| File | Purpose |
|---|---|
| `26-keep-the-call-line-count.dql` | The chart query with the partner sentence removed. |
| `0-pic.md` | Why the partner lines stay out. |
| `1-investigation.md` | The Splunk sums on this screen. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `26-keep-the-call-line-count-follow.txt` | The same steps for a phone. |
| `26.sh` | Copy commands. |

Commands: [26.sh](26.sh)
