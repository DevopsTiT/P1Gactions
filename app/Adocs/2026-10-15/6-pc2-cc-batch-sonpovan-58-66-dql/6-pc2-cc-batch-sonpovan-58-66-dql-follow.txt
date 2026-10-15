# PC2 CC Batch Sonpovan DQL

## Decision tree

```
Splunk line → what does it do?
 plain text search → startsWith(src) + contains or matchesPhrase
 rex (?<loglevel>) then search loglevel="ERROR" → parse loglevel → filter == "ERROR"
 rex failed=(true|false) then search failed=true → contains "failed=true"
 rex max_match=0 (many matches) → splitString + expand + parse + collectArray
 substr(message,401,17) → substring(message, from:400, to:417)
 garbled Japanese or cut off → placeholder → fill in from Splunk
```

## Short takeaway

| Question | Answer |
|---|---|
| Which numbers? | #58 to #66. |
| Ready to run | #59, #60, #61, #63, #64 and #65. |
| Need your input | #58 and #62 (garbled Japanese) and #66 (cut off). |
| Hardest one | #62, because it pulls several 10-digit detail lines out of one log event. |

## Summary

#59, #60, #63 and #64 are simple text searches. #61 and #62 first pull out the log level and keep only ERROR lines. #62 also collects every line that starts with a 10-digit ID. #65 pulls out a claim number and the message text, plus a 17-character slice of the message.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `rex` | Splunk command that pulls a value out of the log text with a regex. |
| `parse` | DQL version of `rex`, using DPL patterns like `DIGIT+` and `LD`. |
| `max_match=0` | Splunk option meaning "keep every match, not just the first". |
| `expand` | DQL command that turns one row with an array into one row per element. |
| `collectArray` | Puts values back together into an array after `expand`. |
| `values()` | Splunk "distinct list of values". In DQL it is `collectDistinct`. |
| `CASE(Message)` | Splunk case-sensitive match. DQL `contains` without `caseSensitive:false` is already case-sensitive. |

### Line by line

| # | Splunk idea | DQL idea |
|---|---|---|
| 58 | bcsubledger Japanese error text | Placeholder `<JP_TEXT>` |
| 59 | pc2-batch "Creation of a payment request for transaction" plus failure | `contains` plus `matchesPhrase` |
| 60 | cc-ui or cc-batch, host contains "cc-", RemoveDocumentChain Execution Duration | `startsWith`, `contains(src)`, three `matchesPhrase` |
| 61 | cc-batch log level ERROR containing EnqueteWorkItem_Adj | parse loglevel, filter ERROR, `contains`, summarize by time |
| 62 | cc-batch ERROR for MessageQueueMonitor_Adj, excluding a Sonpovan message | parse loglevel, `not contains`, cut "Found ..." text, collect 10-digit lines |
| 63 | cc-batch DocNotif_Adj work item with failed=true | Two `contains` |
| 64 | cc-batch FinancialsEsc work item with failed=true | Two `contains` |
| 65 | sonpovan WARN from the account statement tasklet | parse claimNumber and message, take characters 401 to 417 |
| 66 | cc-* | Cut off |

### Notes on tricky parts

| Part | What it means |
|---|---|
| #60 `host="*cc-*"` | In this setup the Splunk host field is the pod name, so it becomes `contains(src, "cc-")`. It is redundant after the `startsWith` check but kept to match Splunk. |
| #62 `prettyPrint` | Splunk joins queueMessage and details with new lines for display. Dynatrace shows the `details` array as a list, so no join is needed. |
| #65 `substr(message,401,17)` | Splunk counts from 1, DQL counts from 0. So start at 400 and stop before 417. |

## Result

All queries are in `6-pc2-cc-batch-sonpovan-58-66-dql.dql`.

| Item | What to do |
|---|---|
| #58 | Paste the real Japanese text into `<JP_TEXT>`. |
| #62 | Paste the real Japanese text after "Sonpovan" into `<JP_TEXT>`. |
| #65 | Check the class name spelling `VanTRecvAccountStatementCallApiTasklet` against Splunk. |
| #66 | Send the full query. |

## Data flow map

```
pc2-batch, cc-ui, cc-batch, bcsubledger, sonpovan pods
 → OneAgent → Dynatrace Grail
 → fetch logs → src filter (startsWith or contains)
 → parse (loglevel, claimNumber, message, detail)
 → filter (ERROR, failed=true, text)
 → summarize or sort → rows
```

## Related files

| File | Purpose |
|---|---|
| `6-pc2-cc-batch-sonpovan-58-66-dql.dql` | All DQL queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Mapping details |
| `2-result.md` | What to do next |
| `3-glossary.md` | Terms |
| `6.sh` | Git one-liners (not run) |

## Commands

See `6.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/6-pc2-cc-batch-sonpovan-58-66-dql
git commit -m "pc2 cc batch sonpovan 58-66 dql"
git push
```
