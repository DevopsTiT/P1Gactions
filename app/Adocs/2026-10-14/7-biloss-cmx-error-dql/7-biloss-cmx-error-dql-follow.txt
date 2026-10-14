# BILoss CMX Error DQL

## Decision tree

```
Splunk → DQL
 host="BILoss-retrieve-files-cmx-prod" → lower(host.name) == "biloss-retrieve-files-cmx-prod"
 search "CMX Error"                    → any case
 regex _raw="CMX Error"                → exact case → net: exact "CMX Error" only
   → contains(content, "CMX Error")    (case sensitive by default)
 strftime, table                       → formatTimestamp, fields
 empty? → check query → swap host filter
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it find? | Lines with exactly "CMX Error" from BILoss-retrieve-files-cmx-prod. |
| Case | The `regex` step makes it exact case, so plain `contains()` is right. |
| Note | Answer 6 searches "CC Error". This one is "CMX Error". Different phrases. |

## Summary

Same structure as answer 5. Splunk does a fast any-case search, then a regex keeps the exact case. DQL does both with one case-sensitive `contains()`.

## Investigation

| Splunk | DQL |
|---|---|
| `host="BILoss-retrieve-files-cmx-prod"` | `filter lower(host.name) == "biloss-retrieve-files-cmx-prod"` |
| `search "CMX Error"` and `regex _raw="CMX Error"` | `filter contains(content, "CMX Error")` |
| `eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")` | `formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")` |
| `table time host _raw` | `fields time, host.name, content` |

## Result

```
fetch logs, from:now()-24h
| filter lower(host.name) == "biloss-retrieve-files-cmx-prod"
| filter contains(content, "CMX Error")
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, content
```

### If it returns 0

| Check query shows the name in | Change the first filter to |
|---|---|
| `log.source` | `filter contains(log.source, "retrieve-files-cmx", caseSensitive:false)` |
| `k8s.pod.name` | `filter startsWith(lower(k8s.pod.name), "biloss-retrieve-files-cmx-prod")` |
| Nowhere | Logs not in Dynatrace. Use 2026-10-13 answer 3. |

## Data flow map

```
BILoss-retrieve-files-cmx-prod logs
  → Dynatrace Grail ? (check query)
  → fetch logs, last 24 h → this host → exact "CMX Error"
  → JST time → newest first → time, host, line
```

## Related files

| File | What it holds |
|---|---|
| `7-biloss-cmx-error-dql.dql` | Main query and check. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Stage mapping. |
| `2-result.md` | Final query. |
| `3-glossary.md` | Words used. |
| `7.sh` | Git one-liners. |
| `Daily Files/2026-10-14/6-biloss-retrieve-files-cmx-dql/` | Same host, 7 phrases. |

## Commands

Run the queries in a Dynatrace Notebook. Git one-liners are in [`7.sh`](./7.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/7-biloss-cmx-error-dql
git commit -m "BILoss CMX error DQL"
git push
```
