# API Count Number Check

```
Splunk row
  four host cells
        |
        v
add the four cells
        |
        +-- equals the ALL cell
        |     row is readable
        |
        +-- does not equal ALL
              one digit in that row is unsafe
        |
        v
compare the safe ALL
  with Dynatrace 13:55 to 14:55
        |
        v
same hour shape
  a few hundred events can move
  customer-info-V1 moved by about 1,900
```

| Check | Result |
|---|---|
| Splunk `customer-info-V2` hosts add up | 26,902, and the ALL cell is 26,902. |
| Dynatrace `customer-info-V2` at 14:55 | 26,991. The gap is 89. |
| Splunk `policy-management-V1` hosts add up | 18,637. |
| Dynatrace `policy-management-V1` | 18,636. The gap is 1. |
| Splunk `customer-info-V1` | 15,451. |
| Dynatrace `customer-info-V1` | 13,512. The gap is 1,939. |

## Summary

On the sharp Splunk grid, the big rows add up across the four hosts. Those totals sit next to the Dynatrace hour from 13:55 to 14:55. `customer-info-V2`, the premium API, and `policy-management-V1` are close. `customer-info-V1` is the row that moved.

## Investigation

The sharp screenshot is the Splunk dashboard `EIP1015 - APIGW - Host vs API`, set to Last 1 hour. Columns are B9, BC, BF, C0, then ALL.

The monitor photo is the same grid. Glare changes digits on that photo, so the arithmetic below uses the sharp screenshot only.

Dynatrace numbers are the 14:55 run. That window is 13:55:45 to 14:55:45. The Splunk picker says Last 1 hour at about 15:07, so the two hours do not cover the same minutes.

`customer-info-V2` on Splunk:

| Host | Splunk | Dynatrace at 14:55 | Gap |
|---|---|---|---|
| B9 | 6,540 | 6,734 | 194 |
| BC | 6,902 | 6,974 | 72 |
| BF | 6,810 | 6,716 | 94 |
| C0 | 6,650 | 6,637 | 13 |
| ALL | 26,902 | 26,991 | 89 |

Splunk arithmetic: 6,540 + 6,902 + 6,810 + 6,650 = 26,902. The ALL cell matches.

Other rows where the four hosts equal the ALL cell:

| API | B9 | BC | BF | C0 | ALL | Dynatrace ALL at 14:55 | Gap |
|---|---|---|---|---|---|---|---|
| `customer-info-V1` | 2,775 | 3,524 | 3,885 | 5,267 | 15,451 | 13,512 | 1,939 |
| `jp-Designing-DesignProduct-CalculatePremiumReserveCashValue-v1-vs` | 3,805 | 3,836 | 3,876 | 3,848 | 15,365 | 15,448 | 83 |
| `jp-Distributing-Sell-GenerateFormImage-v2-vs` | 1,171 | 1,053 | 1,071 | 1,251 | 4,546 | 4,394 | 152 |
| `jp-CoreBusiness-ServiceManagement-ICMCase-v1-vs` | 874 | 453 | 221 | 362 | 1,910 | 1,499 | 411 |
| `jp-CoreBusiness-ServiceManagement-ClaimService-v1-vs` | 271 | 148 | 286 | 371 | 1,076 | 1,086 on the `is-` name | 10 |

The ClaimService gap uses Dynatrace name `is-CoreBusiness-ServiceManagement-ClaimService-v1-vs`. Splunk shows the `jp-` name. Treat that 10 as a nearby row, not a proved same-name match.

Rows where the picture’s ALL cell does not equal the four hosts:

| API | Hosts added | ALL cell on the picture | Dynatrace ALL at 14:55 |
|---|---|---|---|
| `policy-management-V1` | 18,637 | 18,598 | 18,636 |
| `technical-utility-V1` | 3,360 | 3,611 | 3,018 |
| `jp-MarketAccess-DistributionManagement-Commission-v4-vs` | 3,782 | 5,702 | 3,637 |

For `policy-management-V1`, the host sum 18,637 matches Dynatrace 18,636. The ALL cell on the picture is 39 lower, so that one digit is the unsafe one. For the commission v4 row, the host sum 3,782 is near Dynatrace 3,637, and the printed ALL of 5,702 does not belong to those four cells.

## Result

The wide table is counting the same APIs. Re-run the Dynatrace query while this Splunk dashboard is still on Last 1 hour if you want the same minutes. Compare `customer-info-V2` first. A gap of about 100 on that row fits two hours that are a few minutes apart. `customer-info-V1` is the row to look at if the new run is still about 1,900 higher on Splunk.

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
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

## Data flow map

```
Splunk Last 1 hour
  four hosts
  ALL cell
        |
        v
add the four hosts
        |
        v
Dynatrace 13:55 to 14:55
  V2 gap 89
  policy gap 1
  V1 gap 1,939
```

## Related files

| File | Purpose |
|---|---|
| `23-api-count-number-check.dql` | The same wide query, to run against the current Splunk hour. |
| `0-pic.md` | How a row was checked. |
| `1-investigation.md` | The arithmetic. |
| `2-result.md` | Which rows agree. |
| `3-glossary.md` | The words. |
| `23-api-count-number-check-follow.txt` | The same steps for a phone. |
| `23.sh` | Copy commands. |

Commands: [23.sh](23.sh)
