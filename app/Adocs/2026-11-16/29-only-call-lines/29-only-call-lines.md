# Only Call Lines

```
lines that contain API:
        |
        v
one group
  call line  100,482
        |
        v
no partner line
no other API text
        |
        v
the chart already has every API line
in this Dynatrace file
```

| lineKind | Count |
|---|---|
| `call line` | 100,482 |
| `partner line` | no row |
| `other API text` | no row |

## Summary

Every line in this file that contains `API:` also contains `API Version`. The count is 100,482. There is no second group of lines to add to the chart.

## Investigation

The split ran at 15:32:27. The window is 14:32:26 to 15:32:26. Scanned bytes are 5.82 GiB. The result is one record.

The total row two minutes earlier was 100,912, for 14:30:31 to 15:30:31. The window slid forward. 100,912 and 100,482 are the same chart.

The Splunk photo’s bottom line added to 146,964. That is about 46,000 above this Dynatrace count. Those extra events are not stored in this file as a different `API:` sentence. This query would have given them their own row.

## Result

Keep the chart on the call line. The total to compare with Splunk is about 100,500 for this hour.

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

A Splunk bottom line near 147,000 includes events that this Dynatrace file does not have. Changing the parse will not create them.

## Data flow map

```
apigw5590/server.log
  lines with API:
        |
        v
call line only
  100,482
        |
        v
Splunk photo bottom line
  146,964
  the extra events are outside this file
```

## Related files

| File | Purpose |
|---|---|
| `29-only-call-lines.dql` | The total row to keep. |
| `0-pic.md` | One group of API lines. |
| `1-investigation.md` | The 15:32 result. |
| `2-result.md` | What to compare. |
| `3-glossary.md` | The words. |
| `29-only-call-lines-follow.txt` | The same steps for a phone. |
| `29.sh` | Copy commands. |

Commands: [29.sh](29.sh)
