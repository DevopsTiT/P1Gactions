# Why FieldsAdd Check

## Decision tree

```
Records detector query returns rows
 Every row = one violation
 How are violations grouped into problems? → alertIdentityFields[0]
  identity = content   → 8 different lines → up to 8 problems → 8 emails
  identity = host.name → 1 problem per host → host case changes → can split
  identity = check (constant) → all rows same value → 1 problem per night → USE THIS
 Want one problem per host instead? → set identity to host.name
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the line do? | Adds a column called `check` with the same text on every row. |
| Why is it needed? | The detector groups rows into problems by the identity field. A constant value puts all rows in one group. |
| Result | One problem and one email per night instead of one per log line. |
| Is the name `check` special? | No. Any field name works, as long as `alertIdentityFields[0]` uses the same name. |
| Is the value special? | No. It just shows up in the problem details, so a readable value helps. |

## Summary

A Records detector treats every row the query returns as a violation. The `alertIdentityFields[0]` setting tells Dynatrace which field decides "is this the same problem or a new one". Rows with the same value join one problem. `fieldsAdd check = "datalake_batch_result"` gives all 8 nightly lines the same value, so you get one problem per night.

## Line by line

| Line | What it does |
|---|---|
| `fetch logs` | Reads log records |
| `filter contains(log.source, "datalake_transfer.log")` | Keeps only the batch file's lines |
| `fields timestamp, host.name, content` | Keeps only the useful columns |
| `fieldsAdd check = "datalake_batch_result"` | Adds a constant column used for grouping |
| `alertIdentityFields[0] = "check"` | Groups problems by that constant column |

## What the rows look like

| timestamp | host.name | content | check |
|---|---|---|---|
| 02:00:33 | ceaa20bd | Process Start | datalake_batch_result |
| 02:00:33 | ceaa20bd | File LINEBOT.csv is existing | datalake_batch_result |
| 02:00:33 | ceaa20bd | Data sent to UDM successfully | datalake_batch_result |
| 02:00:33 | ceaa20bd | Failed to delete Data LINEBOT.csv | datalake_batch_result |

Every row has the same `check`, so all of them belong to one problem.

## Identity choices compared

| Identity field | Problems per night | When to choose it |
|---|---|---|
| `check` (constant) | 1 | You want one email per batch run. This alert. |
| `host.name` | 1 per host | The same batch runs on several servers and each needs its own alert. |
| `content` | Up to 8 | Almost never. Every distinct line becomes its own problem. |
| `timestamp` | Unpredictable | Never. Time changes on every run and can split problems. |

## Data flow

```
query rows (8 lines at 02:00)
 → each row gets check = "datalake_batch_result"
   → detector groups by check
     → 1 group → 1 problem → 1 email
       → rows age out of the 2 h lookback (about 04:00) → problem closes
```

## Investigation

| What was checked | Finding |
|---|---|
| Records analyzer behaviour | Each returned row is a violation. Grouping uses `alertIdentityFields`. |
| Batch output | 8 lines per night, all different text, same second |
| Host field | Appears in lower and upper case on different nights, so it is not a stable grouping key |

## Result

| Item | Result |
|---|---|
| Keep the line? | Yes. Without a constant identity you risk several problems and emails per night. |
| Change needed? | None. Seq 12 tf stays as is. |
| Optional | Rename the value to something readable; it appears in the problem. |

## Related files

| File | Purpose |
|---|---|
| `../12-datalake-batch-result-source-fix/12-datalake-batch-result-source-fix.tf` | The detector that uses `check` |
| `13.sh` | No new commands; git one-liners only |

## Commands

See `13.sh`. No commands are needed for this explanation.
