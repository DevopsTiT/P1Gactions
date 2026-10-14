# Camunda Operate Error DQL

## Decision tree

```
Splunk → DQL
 sourcetype="camunda-platform"   → not needed (host prefix is enough)
 host="camunda8-prod-operate-*"  → startsWith on host.name or k8s.pod.name
 search "ERROR"                  → any case in Splunk
 regex _raw="ERROR"              → case sensitive → net: uppercase ERROR only
   → contains(content, "ERROR")  (no caseSensitive:false)
 strftime, table                 → formatTimestamp, fields
 empty? → check query → field or onboarding gap
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it find? | Lines with uppercase ERROR from Camunda 8 Operate pods. |
| Why two Splunk steps? | `search` is fast but ignores case. `regex` then keeps only exact uppercase. |
| DQL | One case-sensitive `contains()` does both. |

## Summary

Operate is Camunda 8's web tool for watching and fixing running processes. The search keeps its uppercase ERROR lines and shows time, host and the raw line. The DQL is a prefix filter, one `contains()` and a time format.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Camunda Operate | Camunda 8 web app to see and fix process instances. | The pods being searched. |
| `regex _raw="ERROR"` | Splunk keeps lines where the regex matches, case sensitive. | Removes lowercase "error". |
| `contains()` | DQL text check, case sensitive by default. | Same effect as the regex here. |

### Splunk to DQL

| Splunk | DQL |
|---|---|
| `sourcetype="camunda-platform"` | Not needed. |
| `host="camunda8-prod-operate-*"` | `startsWith(host.name, "camunda8-prod-operate-") or startsWith(k8s.pod.name, "camunda8-prod-operate-")` |
| `search "ERROR"` and `regex _raw="ERROR"` | `filter contains(content, "ERROR")` |
| `eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")` | `formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")` |
| `table time host _raw` | `fields time, host.name, k8s.pod.name, content` |

## Result

```
fetch logs, from:now()-24h
| filter startsWith(host.name, "camunda8-prod-operate-")
    or startsWith(k8s.pod.name, "camunda8-prod-operate-")
| filter contains(content, "ERROR")
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, k8s.pod.name, content
```

### If it returns 0

| Check query shows | Change |
|---|---|
| Names in another field | Use that field. |
| Only a camunda namespace | Filter by `k8s.namespace.name` plus `contains(k8s.pod.name, "operate")`. |
| Nothing | Logs not in Dynatrace. Use 2026-10-13 answer 3. |

## Data flow map

```
camunda8-prod-operate-* pods
  → Dynatrace Grail ? (check query)
  → fetch logs, last 24 h → operate pods → uppercase ERROR
  → JST time → newest first → time, host, pod, line
```

## Related files

| File | What it holds |
|---|---|
| `5-camunda-operate-error-dql.dql` | Main query and check. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Stage mapping. |
| `2-result.md` | Final query. |
| `3-glossary.md` | Words used. |
| `5.sh` | Git one-liners. |
| `Daily Files/2026-10-14/4-camunda-error-fatal-dql/` | Other Camunda components. |

## Commands

Run the queries in a Dynatrace Notebook. Git one-liners are in [`5.sh`](./5.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/5-camunda-operate-error-dql
git commit -m "Camunda operate error DQL"
git push
```
