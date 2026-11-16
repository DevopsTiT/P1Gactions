# Matching Application Second Line

```
lines that mention customer-info-V1
        |
        +--> same name  13,797
        |      API: customer-info-V1 API Version
        |      this is the chart
        |
        +--> not parsed  13,562
               Matching application found for the API: customer-info-V1
               a second sentence about that same call
        |
        v
compare Splunk with 13,797
leave the 13,562 lines out of the chart
```

| Group | Count | What the line says |
|---|---|---|
| `same name` | 13,797 | `API: customer-info-V1 API Version` |
| `not parsed` | 13,562 | `Matching application found for the API: customer-info-V1 and Identifier type: token` |

## Summary

`customer-info-V1` has two sentences in the log. The chart counts the call sentence. The other sentence names the API and then says `Identifier type: token`. Splunk folds those sentences into one event. Adding the second sentence in Dynatrace would count the same call twice.

## Investigation

The split ran at 15:13:47. The window is 14:13:46 to 15:13:46.

| nameMatch | eventCount |
|---|---|
| `not parsed` | 13,562 |
| `same name` | 13,797 |

There is no `other name` row. Nothing was parsed as a different API.

The five sample lines are all host `WPALJA21B9.prprivmgmt.intraxa`. The `API` column is empty. The visible text is:

```
atching application found for the API: customer-info-V1 and Identifier type: token and value
```

The full sentence starts with `Matching application found for the API: customer-info-V1`. After the name, the next words are `and Identifier type: token`. The chart looks for ` API Version` after the name, so this sentence stays out. That is the right outcome.

13,797 and 13,562 are close to each other. One call writes both sentences. Splunk’s earlier `customer-info-V1` total was 15,451 in a different hour. The number to put next to Splunk for this hour is 13,797.

Adding 13,562 to 13,797 makes 27,359. That is about twice the Splunk total, because both sentences would be counted.

## Result

Keep the wide chart as it is. Compare Splunk’s `customer-info-V1` cell with the `same name` count, 13,797, for 14:13 to 15:13.

The second sentence can be counted on its own if you want to see its size:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    and contains(content, "Matching application found for the API:", caseSensitive:false)
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' and Identifier'"
| filter isNotNull(API)
| summarize eventCount = count(), by: { API }
| sort eventCount desc
```

That list is the partner sentence. Leave it out of the host chart.

## Data flow map

```
one API call
        |
        +--> API: customer-info-V1 API Version
        |      Dynatrace counts this
        |      13,797
        |
        +--> Matching application found for the API: customer-info-V1
               Dynatrace stores this too
               13,562
               Splunk keeps it inside the same event
```

## Related files

| File | Purpose |
|---|---|
| `25-matching-application-second-line.dql` | The count of the partner sentence. |
| `0-pic.md` | The two sentences from one call. |
| `1-investigation.md` | The 15:13 result. |
| `2-result.md` | Which number to compare. |
| `3-glossary.md` | The words. |
| `25-matching-application-second-line-follow.txt` | The same steps for a phone. |
| `25.sh` | Copy commands. |

Commands: [25.sh](25.sh)
