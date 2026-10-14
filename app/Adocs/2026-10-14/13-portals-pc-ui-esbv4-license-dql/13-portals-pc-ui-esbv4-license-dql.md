# Portals PC UI ESBv4 License DQL

## Decision tree

```
Which SPL?
 JSON logs with replace + spath (#20, #23–#28)
   → replaceString to unescape → parse "JSON:j" → read j[message][url] and so on
   OpenPipeline already parsed the JSON? → skip replace/parse, use the fields directly
   0 rows? → run the sourcetype check query → keep the matching field
 openshift_stats metric (#21)
   → not a log search → use timeseries on Kubernetes CPU metrics
 license expiry (#22)
   → cut out the date → parse it → keep dates less than 100 days away
 plain phrase search (#29, #30, #31)
   → contains(content, "...", caseSensitive:false)
 nothing found anywhere? → logs not in Dynatrace → onboarding request
```

## Short takeaway

| SPL | What it finds | DQL approach |
|---|---|---|
| #20 | Distinct account numbers per day, portals-amp-frontend | JSON parse, first word, `countDistinctExact` per day |
| #21 | pc-ui CPU usage as % of limit, per pod | `timeseries` usage and limit metrics |
| #22 | esbv4 license expiring within 100 days | Cut date, parse, compare to `now() + 100d` |
| #23 | doCancel with CAUGHT_EXCEPTION_ON_BACKEND, 1 day | JSON parse and filter |
| #24 | doCancel with EXECUTION_COMPLETED, 1 day | Same as #23, other type |
| #25 | doesRefundExist with EXECUTION_COMPLETED, 1 day | Same as #23, other url |
| #26 | isPolicyCancelAvailable with EXECUTION_COMPLETED, 1 week | Same as #23, 7 days |
| #27 | isPolicyCancelAvailable with EXECUTION_COMPLETED, 1 day | Same as #23 |
| #28 | Error level on applySimplePayment, claim-customer apps | JSON parse, `level` and `message.url` |
| #29 | BadInputException ContactName on inssuite-prod | Phrase search |
| #30 | pc2-ui Metaspace exhausted | Phrase search |
| #31 | alfrescoacr "Failed to get lock" | Phrase search |

## Summary

Most of these are JSON log searches. Splunk first strips escaped quotes, then uses `spath` to read JSON fields. DQL does the same with `replaceString` and `parse ..., "JSON:j"`. #21 is a metric, not a log, so it becomes a `timeseries` query. The rest are simple phrase searches. Splunk `sourcetype` and `index` do not exist in Dynatrace, so run the check query once and keep the field that matches.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `spath` | Splunk command that reads fields out of JSON. |
| `parse ..., "JSON:j"` | DQL way to read JSON into a record called `j`. |
| `j[message][url]` | Reads the `url` field inside the `message` object. |
| `replaceString()` | DQL text replace. Used here to remove escaped quotes. |
| `timeseries` | DQL command for metrics (numbers over time), not logs. |
| `countDistinctExact()` | Counts unique values exactly. |
| Metaspace | Java memory area for class data. Running out crashes the app. |

### Mapping highlights

| Splunk piece | DQL piece | Note |
|---|---|---|
| `eval _raw=replace(_raw,"\\\\\"","\"")` | `replaceString(content, "\\\"", "\"")` | Turns `\"` into `"`. |
| `eval _raw=replace(_raw,"\\\\","")` | `replaceString(..., "\\", "")` | Removes leftover backslashes. |
| `spath` | `parse raw, "JSON:j"` | |
| `search message.url="doCancel"` | `msg_url == "doCancel"` | Splunk ignores case here. Use `lower()` if needed. |
| `rex "(?<accountNo>\w+)(?<accountNo2>\s.+)"` | `substring(acct, from:0, to:indexOf(acct, " "))` | Keeps the first word. |
| `dedup accountNo date` then `timechart count span=1day` | `countDistinctExact(accountNo)` per day | Same result. |
| `openshift_stats_cpu_percent_of_limit` | `cpu_usage / limits_cpu * 100` | From Kubernetes metrics. |
| `openshift_deploymentconfig_name=pc-ui` | `k8s.workload.name == "pc-ui"` | |
| `strptime(..., "%a %b %d %T JST %Y")` | Remove `JST`, parse, subtract 9 hours | JST is UTC+9. |
| `relative_time(now(), "+100d")` | `now() + 100d` | |
| `earliest=-1d` | `from:now()-1d` | |
| `earliest=-1w` | `from:now()-7d` | |

### Things to verify

| Item | Why |
|---|---|
| Sourcetype field | Dynatrace has no sourcetype. The check query shows the right field. |
| JSON already parsed | If OpenPipeline parses JSON, skip the replace and parse steps. |
| #21 metric names | Confirm `dt.kubernetes.container.cpu_usage` and `limits_cpu` exist in your tenant. |
| #21 host `ljpiosa*` | Not added. Add a cluster or node filter if pc-ui runs in more than one cluster. |
| #29 Japanese text | Unreadable in the screenshot. Add it as a second `contains()` if needed. |

## Result

All queries are in `13-portals-pc-ui-esbv4-license-dql.dql`. The chat reply has every query in full.

## Data flow map

```
JSON apps (#20, #23–#28)
  portals pods -> log line with escaped JSON
  -> replaceString (unescape) -> parse JSON
  -> filter url / type / level -> count or list

Metric (#21)
  pc-ui containers -> Kubernetes CPU usage and limit
  -> average per pod -> usage / limit * 100

License (#22)
  esbv4 -> "Expiration Date = ..." line
  -> cut date -> parse -> earlier than now + 100 days -> list

Phrase (#29, #30, #31)
  app logs -> source filter -> phrase filter -> newest first
```

## Related files

| File | What it holds |
|---|---|
| `13-portals-pc-ui-esbv4-license-dql.dql` | All queries and the check query |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Mapping notes |
| `2-result.md` | Result summary |
| `3-glossary.md` | Glossary |
| `13.sh` | Git one-liners |

## Commands

See `13.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/13-portals-pc-ui-esbv4-license-dql
git commit -m "Portals, pc-ui, esbv4 license DQL"
git push
```
