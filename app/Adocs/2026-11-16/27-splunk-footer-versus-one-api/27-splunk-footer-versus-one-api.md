# Splunk Footer Versus One API

```
Splunk bottom line
  about 35,000 on each host
  about 147,000 in ALL
        |
        v
that line adds every API
        |
        v
Dynatrace row
  one API
  policy-management-V1 is about 18,900
        |
        v
same API on both screens
  ALL is close
  one host cell can still move
```

| What you are looking at | What the number is |
|---|---|
| Splunk bottom line, one host | Every API on that host added together. |
| Splunk bottom line, ALL | Every API on every host. About 147,000. |
| Dynatrace `policy-management-V1` | One API. About 18,900. |
| Dynatrace `myasa-V1` | One API. 437 on both screens. |

## Summary

The two screens were taken about one minute apart. The API rows that can be read on both screens have close ALL totals. The large numbers at the bottom of Splunk are the sum of every API, and the Dynatrace table does not print that sum.

## Investigation

Dynatrace ran at 15:26:35. Its window is 14:26:34 to 15:26:34. The Splunk photo is 15:27, Last 1 hour. The hours share almost the same minutes.

Splunk’s bottom line reads:

| Host | Bottom line |
|---|---|
| B9 | 35,089 |
| BC | 35,427 |
| BF | 39,119 |
| C0 | 37,329 |

35,089 + 35,427 + 39,119 + 37,329 = 146,964. That is the ALL total of every API.

Rows that show up on both screens:

| API | Splunk ALL | Dynatrace ALL |
|---|---|---|
| `jp-MarketAccess-DistributionManagement-Commission-GetCommissionForSPW-v1-vs` | 190 | 190 |
| `myasa-V1` | 437 | 437 |
| `jp-MarketAccess-InteractionManagement-RequestService-v1-vs` | 1,337 | 1,302 |
| `jp-Producing-Underwrite-XRegisterNewBusinessApplicationFor-v1-vs` | about 480 | 476 |
| `technical-utility-V1` | about 3,220 | 2,995 |
| `policy-management-V1` | about 18,800 | 18,851 |

`policy-management-V1` in Dynatrace reads 4,652, 4,877, 4,336, and 5,086. Those four add to 18,951. The ALL cell reads 18,851. One digit on that row is off by 100. It is still the same size as Splunk.

`RequestService` ALL is 1,337 and 1,302. The BC cell is 317 on Splunk and 212 in Dynatrace. The calls are in the total. A slice of them is filed under a different host.

## Result

Paste this to get the one total row. Put it next to Splunk’s bottom line.

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
  }
```

Splunk’s bottom line to compare is 35,089, 35,427, 39,119, 37,329, and 146,964.

The per-API table you already have stays as it is. `policy-management-V1` near 18,900 is one API inside that 146,964.

## Data flow map

```
each API row
  policy about 18,900
  myasa 437
        |
        v
add every API
        |
        v
Splunk bottom line
  about 35,000 per host
  146,964 in ALL
```

## Related files

| File | Purpose |
|---|---|
| `27-splunk-footer-versus-one-api.dql` | The one-row total. |
| `0-pic.md` | One API versus the footer. |
| `1-investigation.md` | The rows compared. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `27-splunk-footer-versus-one-api-follow.txt` | The same steps for a phone. |
| `27.sh` | Copy commands. |

Commands: [27.sh](27.sh)
