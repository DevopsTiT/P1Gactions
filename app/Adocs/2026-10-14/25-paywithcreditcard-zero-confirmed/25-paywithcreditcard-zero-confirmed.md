# PayWithCreditCard Zero Confirmed

## Decision tree

```
Query: portals-amp-backend + payWithCreditCard_Adj + EXECUTION_COMPLETED, last 24h
 → 0 records (84.45 GiB scanned)
 Same as the earlier name check (0 records, 171 GiB) → two queries agree

 Last check 1: text "payWithCreditCard_Adj" with NO app filter
   rows? → logs exist under another name → use that field
   0 → go on
 Last check 2: buckets list
   expected bucket missing? → permission request
 Last check 3 / 4: host and workload entities
   pods seen, no logs → onboarding request (add namespace to forwarder)
   pods not seen → onboarding request + OneAgent coverage question
```

## Short takeaway

| Question | Answer |
|---|---|
| What did you run? | The DQL from answer 24, first four lines, with the 24-hour time picker. |
| Result | 0 records, 84.45 GiB scanned. |
| Is the query wrong? | No. The filter is the same as the Splunk logic and would find any matching line. |
| What does it confirm? | Dynatrace has no portals-amp-backend payment logs. |
| What is left to do? | Run last check 1 once, then send the onboarding request (answer 21). |

## Summary

Two different queries now return nothing: the broad name check (answer 21) and this payment filter. Splunk shows about 75 of these events every hour, so the data exists but never reaches Dynatrace. One last search for the API name with no app filter will remove any doubt, and then the next step is the onboarding request.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Scanned bytes | How much log data Grail read. Here 84.45 GiB. |
| Time picker | The "Last 24 hours" setting. Used when the query has no `from:`. |
| Bucket | A Grail storage area with its own access rules. |
| Entity | Something Dynatrace monitors, such as a host or a workload. |
| Onboarding | Adding an app's logs to Dynatrace. |

### Reading the screen

| Part | What it shows | What it means |
|---|---|---|
| Line 1 `fetch logs` | No `from:` | Uses the time picker, Last 24 hours. |
| Line 2 `src = lower(coalesce(k8s.pod.name, host.name))` | Helper field | Pod name, or host name if no pod name. |
| Line 3 `startsWith(src, "portals-amp-backend")` | App filter | Same pods as in Splunk. |
| Line 4 two `contains()` | Text filter | Same words as the Splunk search. |
| `0 records` | Nothing matched | No such lines in Dynatrace. |
| Timeframe 10/13 17:13 to 10/14 17:13 | A full day | Not a quiet-hour issue. |
| Scanned 84.45 GiB | Less than the 171 GiB earlier | Grail skipped data it could rule out quickly. Normal. |

### Evidence so far

| Check | Result |
|---|---|
| Splunk #85 (answer 19) | 75 events in 1 hour, from 2 portals-amp-backend pods, read from S3. |
| Dynatrace name check (answer 21) | 0 records in 24 hours, 171 GiB scanned. |
| Dynatrace payment filter (this screen) | 0 records in 24 hours, 84 GiB scanned. |

### Last checks

| Check | What it rules out |
|---|---|
| 1. Text search with no app filter | The app name is stored somewhere unexpected. |
| 2. Bucket list | You lack permission for the bucket holding these logs. |
| 3. Host entities | Whether Dynatrace sees the pods at all. |
| 4. Workload entity | Gives the namespace name for the request. |

## Result

| If last check 1 shows | Meaning | Next step |
|---|---|---|
| Rows | Logs exist under another name. | Change the app filter to that field. |
| 0 records | Logs are not in Dynatrace. | Send the onboarding request from answer 21. |

The DQL in answer 24 is correct and ready. It will start returning rows once the logs are onboarded.

## Data flow map

```
portals-amp-backend pods
  -> S3 forwarder -> Splunk      (75 per hour)
  -X-> Dynatrace                 (0 in 24 hours, two queries)

Fix: add the portals-amp namespace to the ClusterLogForwarder Dynatrace output
  -> Grail -> answer 24 DQL returns rows
```

## Related files

| File | What it holds |
|---|---|
| `25-paywithcreditcard-zero-confirmed.dql` | Last checks 1 to 4 |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Evidence |
| `2-result.md` | Next step |
| `3-glossary.md` | Glossary |
| `25.sh` | Git one-liners |
| Answer 21 | Onboarding request, English and Japanese |
| Answer 24 | Final DQL |

## Commands

See `25.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/25-paywithcreditcard-zero-confirmed
git commit -m "payWithCreditCard zero confirmed"
git push
```
