# API Line Is Cut Off

```
host count returned 4 hosts
  BF  BC  C0  B9
        |
        v
sample lines also returned
  content stops at [default][WPA
  API: is later in the same line
        |
        v
print 120 characters starting at API:
        |
        v
then read the API name from that short text
```

| What the notebook showed | What it means |
|---|---|
| Four host names | The file filter finds the same four gateways as Splunk. |
| Content starts with the timestamp | The API name is not at the front of the line. |
| The cell ends at `[default][WPA` | The notebook hid the rest of the line. |
| The filter asked for `API:` | Those three lines do contain `API:` later in the text. |

## Summary

The host query works. The sample query also works, and the notebook is only showing the start of each line. Print a short piece that begins at `API:` so the API name is visible.

## Investigation

The host query ran at 14:38:55. The window is 13:38:55 to 14:38:55.

| Host | Dynatrace count | Splunk popup count |
|---|---|---|
| `WPALJA21BF.prprivmgmt.intraxa` | 122,812 | 30,401 |
| `WPALJA21BC.prprivmgmt.intraxa` | 114,665 | 32,913 |
| `WPALJA21C0.prprivmgmt.intraxa` | 112,272 | 31,448 |
| `WPALJA21B9.prprivmgmt.intraxa` | 111,935 | 30,971 |

Dynatrace total for this hour is 461,684. The Splunk host popup added up to 125,733. The Splunk Events tab said 113,154, and that search was paused. The host names match. The counts do not. Keep the two tools as two counts until a full line shows what Dynatrace stored.

The three sample rows are all `WPALJA21BC.prprivmgmt.intraxa`. The visible text is:

```
2026-11-16 14:38:32.370 JST [YAI.0900.0005I] (tid=924) [default][WPA
2026-11-16 14:38:33.039 JST [YAI.0900.0005I] (tid=924) [default][WPA
2026-11-16 14:38:33.098 JST [YAI.0900.0005I] (tid=924) [default][WPA
```

That message code is `YAI.0900.0005I`. The Splunk sample from the same file started with `YAI.0102.0011`. Both can live in this file. The notebook column stops before `API:`.

## Result

Show the text around `API:`:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    and contains(content, "API:", caseSensitive:false)
| fieldsAdd apiAt = indexOf(lower(content), "api:")
| fieldsAdd apiSnippet = substring(content, from: apiAt, to: apiAt + 120)
| fields timestamp, host.name, apiSnippet
| limit 5
```

`apiSnippet` should start with `API:` and then the name. Paste one full `apiSnippet` value back.

This check shows whether the path filter is one file or several:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| summarize eventCount = count(), by: { log.source }
| sort eventCount desc
```

One row means Dynatrace has about 461,684 lines for that exact path in this hour. More than one row means the `contains` filter matched extra paths.

## Data flow map

```
server.log
  four hosts
  about 461,684 lines in Dynatrace
        |
        v
content cell
  shows the timestamp
  hides the later text
        |
        v
apiSnippet
  120 characters from API:
        |
        v
the API name used by the chart
```

## Related files

| File | Purpose |
|---|---|
| `18-api-line-cut-off.dql` | The snippet query and the path check. |
| `0-pic.md` | From the cut-off cell to the short snippet. |
| `1-investigation.md` | The host counts and the three sample lines. |
| `2-result.md` | The queries to paste. |
| `3-glossary.md` | The words. |
| `18-api-line-cut-off-follow.txt` | The same steps for a phone. |
| `18.sh` | Copy commands. |

Commands: [18.sh](18.sh)
