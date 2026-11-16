# Why Some API Counts Differ

```
same hour shape
  V2 gap is 89
  policy gap is 1
        |
        v
V1 gap is 1,939
        |
        v
a line is kept only when it has
  API: <exact name> API Version
        |
        v
count three groups for customer-info-V1
  same name
  other name
  not parsed
```

| API | Splunk ALL | Dynatrace ALL | Gap |
|---|---|---|---|
| `customer-info-V2` | 26,902 | 26,991 | 89 |
| `policy-management-V1` | 18,637 from the four hosts | 18,636 | 1 |
| Premium cash value API | 15,365 | 15,448 | 83 |
| `customer-info-V1` | 15,451 | 13,512 | 1,939 |

## Summary

The small gaps fit two Last-hour windows that are a few minutes apart. `customer-info-V1` is short by 1,939 lines. The current parse keeps a line only when the text is `API: ` plus that exact name plus ` API Version`. Lines Splunk still calls `customer-info-V1` can miss that shape.

## Investigation

Splunk’s grid counts the field `API` on each event. Dynatrace counts a line only after this parse:

```
DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'
```

`customer-info-V2` was 26,902 on Splunk and 26,991 in Dynatrace. `policy-management-V1` was 18,637 from the four host cells and 18,636 in Dynatrace. The premium API was 15,365 and 15,448. Those three moved by less than a few hundred events.

`customer-info-V1` was 15,451 on Splunk and 13,512 in Dynatrace. The Dynatrace window was 13:55 to 14:55. Splunk Last 1 hour at 15:07 is about 14:07 to 15:07. A few minutes of clock difference fits the V2 gap. It does not fit a V1 gap of 1,939.

`jp-CoreBusiness-ServiceManagement-ICMCase-v1-vs` was 1,910 on Splunk and 1,499 in Dynatrace. That gap is 411. It is the same kind of gap, on a smaller API.

## Result

Run this on `customer-info-V1`. It splits every line that mentions that name.

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    and contains(content, "customer-info-V1", caseSensitive:false)
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'"
| fieldsAdd nameMatch = if(API == "customer-info-V1", "same name", else: if(isNotNull(API), "other name", else: "not parsed"))
| summarize eventCount = count(), by: { nameMatch }
```

| nameMatch | What it means |
|---|---|
| `same name` | The parse kept `customer-info-V1`. These are the lines in the current chart. |
| `other name` | The line mentions V1, and the parse returned a different API name. |
| `not parsed` | The line mentions V1, and it does not have `API: ` then ` API Version`. Splunk can still count these. |

Then show five of the lines that did not stay as `customer-info-V1`:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    and contains(content, "customer-info-V1", caseSensitive:false)
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'"
| filter isNull(API) or API != "customer-info-V1"
| fieldsAdd apiAt = indexOf(lower(content), "customer-info-v1")
| fieldsAdd startAt = if(apiAt > 40, apiAt - 40, else: 0)
| fieldsAdd apiSnippet = substring(content, from: startAt, to: apiAt + 80)
| fields host.name, API, apiSnippet
| limit 5
```

Paste one `apiSnippet`. The characters around `customer-info-V1` show which pattern to add.

For ICMCase, use the same two queries and replace `customer-info-V1` with `jp-CoreBusiness-ServiceManagement-ICMCase-v1-vs`. In the `indexOf` line use `jp-corebusiness-servicemanagement-icmcase-v1-vs`.

## Data flow map

```
Splunk event
  field API = customer-info-V1
        |
        v
Dynatrace line
  text contains customer-info-V1
        |
        +--> API: customer-info-V1 API Version
        |      counted in the chart
        |
        +--> different words around the name
               left out of the chart
               this is the V1 gap
```

## Related files

| File | Purpose |
|---|---|
| `24-why-some-api-counts-differ.dql` | The split count and the five-line snippet. |
| `0-pic.md` | Where the V1 lines go. |
| `1-investigation.md` | The gaps. |
| `2-result.md` | The queries to paste. |
| `3-glossary.md` | The words. |
| `24-why-some-api-counts-differ-follow.txt` | The same steps for a phone. |
| `24.sh` | Copy commands. |

Commands: [24.sh](24.sh)
