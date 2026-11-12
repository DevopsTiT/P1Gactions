# Records Or Timeseries

```
Which data type on the Advanced tab?
  you want one number per minute, then a threshold
    choose Timeseries
    query ends in makeTimeseries, interval 1m
    alert if the count is above 0
  the query itself returns only the bad rows
    choose Records
    filter loglevel == ERROR before Save
    identity field aws.log.group keeps one open problem per function
  the query returns every line in the log group
    Records stays open while the function writes START and END
    add the ERROR filter, or switch to Timeseries
```

| Data type | The query returns | The alert fires when |
|---|---|---|
| Timeseries | A count for each minute. | That count crosses the threshold. |
| Records | Individual log lines. | A matching line is in the result. |

## Summary

Choose Timeseries for this Lambda error. The query counts ERROR lines once a minute, and the threshold is above 0. Choose Records only when the query already returns just the bad lines. The draft query returns every line in the log group, so Records would stay open during normal START and END lines.

## Investigation

| Item on the screen | What it implies |
|---|---|
| Data type Records is selected | Each result row can keep an alert open. |
| Query | The e-signature log group, with no ERROR filter. |
| Identity field | `aws.log.group`. Every line from that function shares one identity. |
| Notebook | 144 lines in two hours, including START, END, REPORT, and Failed to handle. |
| Dynatrace docs | Timeseries alerts on a threshold. Records alerts on rows the query returns. |
| Records timeframe | With no `from:` in the query, Dynatrace uses the last 2 hours. |

## Result

Use Timeseries for the failure you saw.

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/light-digital-api-dev-confirm-e-signature", caseSensitive:false)
| filter loglevel == "ERROR"
| makeTimeseries error_count = count(), interval:1m
```

On the form, set the static threshold to above 0.

| Minute | What happens |
|---|---|
| The count is 0 | The alert stays quiet. |
| The count is 1 or more | One problem opens. |
| Several Failed to handle lines arrive in the same minute | They stay inside that one problem. |

Use Records when you want the query to be the whole condition.

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/light-digital-api-dev-confirm-e-signature", caseSensitive:false)
| filter loglevel == "ERROR"
```

Keep the identity field `aws.log.group`. While an ERROR line is inside the last 2 hours, one problem stays open for that function. When those lines age out, the problem can close. A new line with the same log group updates that problem. It does not open a second one.

| Draft as it is now | Result if you press Save |
|---|---|
| Records, and the query has no ERROR filter | Any START or END line is a matching row. |
| Same log group on every row | One problem stays open for as long as the function writes logs. |

## Data flow map

```
Log lines from the e-signature function
        |
        +--> Timeseries
        |      keep ERROR
        |      count per minute
        |      above 0 → one problem
        |
        +--> Records
               query returns only ERROR rows
               identity aws.log.group
               one open problem while those rows exist
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Which data type to pick. |
| `1-investigation.md` | What the open form is doing. |
| `2-result.md` | The two queries. |
| `3-glossary.md` | The words. |
| `5-records-or-timeseries-follow.txt` | The same answer for a phone. |
| `5.sh` | Copy commands. |

Commands: [5.sh](5.sh)
