# Dynatrace Dummy Data For Testing

## Decision tree

```
I want to test a DQL with fake data
 Only checking filter / parse / lookup logic?
   → use the DQL `data` command in a notebook (nothing stored, free, no token)
 Need the data stored in Grail (fetch logs must find it, alerts, dashboards)?
   → send logs to the Log ingest API with an API token (logs.ingest)
   → test tenant if possible
   → mark every line DUMMY-TEST and log.source="dummy-test"
 Testing a metric query (#21 CPU)?
   → data command with timeseries-shaped records, or Metrics ingest API
 Testing a lookup file (#81 SSL)?
   → data command with the same columns, or upload a lookup file
 Ingested but fetch returns 0?
   → widen the time range (timestamp in the past?)
   → filter log.source == "dummy-test" only
   → wait 1 to 2 minutes for ingest
```

## Short takeaway

| Question | Answer |
|---|---|
| Fastest way? | Replace `fetch logs, from:...` with `data record(...), record(...)`. Everything after the first line stays the same. |
| Does `data` store anything? | No. The records live only while the query runs. Nothing to clean up. |
| When do I need real ingest? | When `fetch logs` itself, alerts, or dashboards must see the data. |
| Biggest risk of real ingest? | Fake error lines can fire real alerts, SILVA incidents or PagerDuty pages. |
| Can I delete ingested test logs? | Not easily. They stay until the bucket retention ends. That is why `data` is the first choice. |

## Summary

For almost every test of the 85 queries, use the `data` command: you paste the sample lines from answer 17 as records and run the rest of the query unchanged. Only use the Log ingest API when you must prove the full path (storage, `fetch`, alerting), and then do it in a test tenant with clearly marked lines.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Notebook | A Dynatrace page where you write and run DQL. |
| Grail | Dynatrace storage. `fetch logs` reads from it. |
| `data` command | A DQL command that makes records inside the query instead of reading Grail. |
| `record(...)` | One fake row. Each `name = value` becomes a field. |
| Ingest | Sending data into Dynatrace so it is stored. |
| API token | A secret key that allows a program to call the Dynatrace API. |
| Scope | The permission inside a token, for example `logs.ingest`. |
| Bucket retention | How long Grail keeps stored records before deleting them. |

### Option 1: the `data` command (recommended)

How it works: the first line `fetch logs, from:now()-24h` is the only line that reads storage. Swap it for `data` and the rest of the query runs on your fake rows.

#### Example A: test #7 (simple text filter)

```
data record(timestamp = now(), host.name = "BILoss-retrieve-files-cmx-prod", content = "2026-10-15 09:12:34.567 ERROR CmxFileFetcher - CMX Error: response code 500"),
     record(timestamp = now(), host.name = "BILoss-retrieve-files-cmx-prod", content = "2026-10-15 09:12:35.000 INFO CmxFileFetcher - file list retrieved"),
     record(timestamp = now(), host.name = "other-host-prod", content = "CMX Error from a different host")
| filter lower(host.name) == "biloss-retrieve-files-cmx-prod"
| filter contains(content, "CMX Error")
| fields timestamp, host.name, content
```

| Line | What it does |
|---|---|
| `data record(...), record(...), record(...)` | Makes three fake log rows. |
| Row 1 | Should match: right host and contains `CMX Error`. |
| Row 2 | Should be dropped: right host but no `CMX Error`. |
| Row 3 | Should be dropped: has `CMX Error` but the wrong host. |
| The rest | Exactly the lines from the real #7 query. |

Expected result: 1 row. If you get 1 row, the filter logic is correct.

#### Example B: test #50 (parse plus exact value)

```
data record(content = "GmoClient - EntryTran: errcode=E01&errinfo=E01170006&OrderID=ORD-1"),
     record(content = "GmoClient - EntryTran: errcode=E01050004&OrderID=ORD-2")
| parse content, "LD 'errcode=' ALNUM:errcode"
| fields errcode, content
```

Expected: row 1 shows `errcode = E01`, row 2 shows `errcode = E01050004`. Add `| filter errcode == "E01"` and only row 1 stays. This proves the parse pattern before you trust it on real logs.

#### Example C: test #78 (lookup join)

Both the outer query and the inner query use `data`, so you control both sides.

```
data record(timestamp = now(), k8s.pod.name = "esbv4-dummy-0", content = "[requestId=5d6e7f80-91a2-4b3c-8d4e-5f6a7b8c9d0e] Sending request to /esb/ebroker/inswebauto/online/_quote"),
     record(timestamp = now(), k8s.pod.name = "esbv4-dummy-0", content = "[requestId=11111111-2222-4333-8444-555555555555] Sending request to /esb/ebroker/inswebauto/online/_quote")
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/inswebauto/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    data record(content = "[requestId=5d6e7f80-91a2-4b3c-8d4e-5f6a7b8c9d0e] Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.")
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
| fields timestamp, src, query, content
```

Expected: 1 row, the `5d6e7f80-...` request. The `11111111-...` request has no timeout line, so it is dropped.

#### Example D: test #85 (escaped JSON)

The real log stores `\"` before every quote. Inside a DQL string, `\\` means one backslash and `\"` means one quote, so `\\\"` produces `\"`.

```
data record(timestamp = now(), k8s.container.name = "portals-amp-backend", content = "{\\\"level\\\":\\\"info\\\",\\\"message\\\":{\\\"url\\\":\\\"https://portals-amp-backend.example.internal/api/payment/payWithCreditCard_Adj\\\",\\\"type\\\":\\\"EXECUTION_COMPLETED\\\",\\\"request_id\\\":\\\"req-1\\\",\\\"target_system\\\":\\\"payment-gateway\\\"}}")
| filter contains(content, "payWithCreditCard_Adj")
| filter contains(k8s.container.name, "portals-amp") or contains(k8s.pod.name, "portals-amp") or contains(log.source, "portals-amp") or contains(host.name, "portals-amp")
| fieldsAdd raw = replaceString(content, "\\\"", "\"")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type]), request_id = toString(j[message][request_id]), target_system = toString(j[message][target_system])
| filter contains(msg_url, "payWithCreditCard_Adj")
| filter msg_type == "EXECUTION_COMPLETED"
| fields timestamp, msg_type, request_id, target_system, msg_url, raw
```

Expected: 1 row. This proves #85 works today, even though the real portals-amp logs are not in Dynatrace yet.

#### Example E: test #81 (lookup file) without uploading

```
data record(dest = "ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa", ssl_end_time = 1793836800),
     record(dest = "ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa", ssl_end_time = 1798675200)
| fieldsAdd ssl_end = timestampFromUnixSeconds(toLong(ssl_end_time))
| fieldsAdd days_left = toLong((ssl_end - now()) / 1d)
| filter ssl_end < now() + 30d
| fields dest, ssl_end, days_left
```

Expected on 2026-10-15: 1 row (5 November, about 20 days left). The 31 December row is dropped.

#### Tips for the `data` command

| Tip | Why it matters |
|---|---|
| Add rows that should NOT match | Proves the filter drops the right things, not just keeps everything. |
| Copy the sample lines from answer 17 | They were written to pass each query's filters. |
| If a dotted name like `k8s.pod.name` errors inside `record()`, wrap it in backticks | Some editors want `` `k8s.pod.name` = "..." `` for names with dots. |
| `timestamp = now()` | Gives the row a time, so `sort timestamp` and `formatTimestamp` work. |
| Use `timestamp = now() - 2h` | Lets you test "silent host" queries such as #18 and #76. |

### Option 2: real log ingest (stored in Grail)

Use this only when the data must be stored, for example to test that `fetch logs` finds it, or to test a log alert or a workflow trigger.

What you need:

| Item | What it means |
|---|---|
| Environment URL | `https://<ENV_ID>.live.dynatrace.com` (or your managed URL). |
| API token | Created in Access tokens with the scope `logs.ingest`. Keep it in an environment variable, never in a file you commit. |
| JSON body | A list of log records. See `18-dynatrace-dummy-data-testing-logs-ingest.json`. |

Body example (also in the JSON file):

```json
[
  {
    "timestamp": "2026-10-15T09:12:34.567+09:00",
    "log.source": "dummy-test",
    "host.name": "dummy-test-host",
    "k8s.pod.name": "esbv4-dummy-0",
    "content": "DUMMY-TEST [requestId=5d6e7f80-91a2-4b3c-8d4e-5f6a7b8c9d0e] Sending request to /esb/ebroker/inswebauto/online/_quote"
  }
]
```

Send it (in `18.sh`, not run):

```
curl -X POST "https://<ENV_ID>.live.dynatrace.com/api/v2/logs/ingest" -H "Authorization: Api-Token $DT_TOKEN" -H "Content-Type: application/json; charset=utf-8" --data @"<path>/18-dynatrace-dummy-data-testing-logs-ingest.json"
```

| Step | What happens |
|---|---|
| 1 | Dynatrace answers `204` when the records are accepted. |
| 2 | Wait 1 to 2 minutes. |
| 3 | Run `fetch logs, from:now()-2h \| filter log.source == "dummy-test"` to see them. |
| 4 | Run the real query (for example #78). The pod name `esbv4-dummy-0` makes `startsWith(src, "esbv4")` true. |

Safety rules for real ingest:

| Rule | Why |
|---|---|
| Use a test tenant if you have one | Production log alerts and workflows read the same data. |
| Put `DUMMY-TEST` in every `content` | Anyone who sees the line knows it is fake. |
| Set `log.source = "dummy-test"` | Easy to filter in, and easy to exclude from alerts. |
| Check log alerts and workflows first | A fake `Timeout exceeded.` line could open a SILVA incident or page PagerDuty. |
| Keep the timestamp within the last day | Records older than the allowed window are rejected, and old timestamps fall outside a 1h query. |
| Expect the data to stay | Ingested records live until the bucket retention ends. You pay for the ingest. |

### Option 3: metrics (for #21)

For a quick logic test, use the `data` command with number fields. If the metric must really exist, send a custom metric with a token that has `metrics.ingest`:

```
curl -X POST "https://<ENV_ID>.live.dynatrace.com/api/v2/metrics/ingest" -H "Authorization: Api-Token $DT_TOKEN" -H "Content-Type: text/plain; charset=utf-8" --data-binary "custom.dummy.cpu_usage,k8s.pod.name=pc-ui-dummy 250"
```

Note: a custom metric has a different name from `dt.kubernetes.container.cpu_usage`, so change the metric name in the `timeseries` line while testing.

### Option 4: lookup files (for #81)

Example E above is enough to test the logic. To test `load "/lookups/..."` itself, upload a small table (columns `dest` and `ssl_end_time`) through your tenant's lookup upload feature (Resource Store API or the UI if available). This needs a platform token or OAuth client with storage file write permission. Check your tenant's docs for the exact path, because it differs by version.

## Result

| Goal | Do this |
|---|---|
| Check a query's filter logic | Option 1: `data` command with matching and non-matching rows. |
| Check a portals-amp query before onboarding | Option 1, Example D. |
| Check the full path including storage and alerts | Option 2 in a test tenant, marked `DUMMY-TEST`. |
| Check a metric query | Option 1, or Option 3 with a custom metric name. |
| Check a lookup query | Option 1, Example E. |

The ready-to-paste DQL for Examples A to E is in `18-dynatrace-dummy-data-testing-examples.dql`.

## Data flow map

```
Option 1 (data command)
 notebook → data record(...) → your filter lines → result
 (nothing stored, nothing to clean up)

Option 2 (log ingest)
 JSON file → curl POST /api/v2/logs/ingest (token: logs.ingest)
 → Grail logs bucket → fetch logs → your query → result
 → ALSO seen by log alerts, workflows, dashboards (be careful)
```

## Related files

| File | Purpose |
|---|---|
| `18-dynatrace-dummy-data-testing.md` | This answer |
| `18-dynatrace-dummy-data-testing-examples.dql` | DQL Examples A to E ready to paste |
| `18-dynatrace-dummy-data-testing-logs-ingest.json` | Sample body for the Log ingest API |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Option comparison |
| `2-result.md` | What to do |
| `3-glossary.md` | Terms |
| `18.sh` | curl and git one-liners (not run) |
| 2026-10-15 answer 17 | Sample lines to paste into `data record(...)` |

## Commands

See `18.sh`. None of these commands have been run. Set `DT_TOKEN` yourself in the terminal; never write the token into a file.

```
curl -X POST "https://<ENV_ID>.live.dynatrace.com/api/v2/logs/ingest" -H "Authorization: Api-Token $DT_TOKEN" -H "Content-Type: application/json; charset=utf-8" --data @"/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-15/18-dynatrace-dummy-data-testing/18-dynatrace-dummy-data-testing-logs-ingest.json"
curl -X POST "https://<ENV_ID>.live.dynatrace.com/api/v2/metrics/ingest" -H "Authorization: Api-Token $DT_TOKEN" -H "Content-Type: text/plain; charset=utf-8" --data-binary "custom.dummy.cpu_usage,k8s.pod.name=pc-ui-dummy 250"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/18-dynatrace-dummy-data-testing
git commit -m "dynatrace dummy data testing"
git push
```
