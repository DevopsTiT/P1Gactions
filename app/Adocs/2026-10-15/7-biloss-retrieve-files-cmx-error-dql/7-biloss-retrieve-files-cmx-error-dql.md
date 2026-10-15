# BILoss Retrieve Files CMX Error DQL

## Decision tree

```
Run #7 main query
 rows returned? → the retrieve-files job hit a CMX Error → read content for the cause
 0 rows? → run the host check
            host listed → no "CMX Error" in 24h, healthy
            host missing → BILoss logs are not in Dynatrace, or the host name differs
            similar name listed → copy that exact name into the main query
```

## Short takeaway

| Question | Answer |
|---|---|
| What does #7 find? | Log lines from host BILoss-retrieve-files-cmx-prod that contain "CMX Error". |
| Why case-sensitive? | Splunk `regex _raw="CMX Error"` is case-sensitive, so DQL uses `contains` without `caseSensitive:false`. |
| How is time shown? | `formatTimestamp` in Asia/Tokyo, like the Splunk `strftime`. |

## Summary

Splunk first does a case-insensitive search for "CMX Error", then `regex` keeps only exact-case matches. DQL needs only one case-sensitive `contains`. The host match follows yesterday's #9 BILoss query.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `host=` | Splunk host field. Here it is the BILoss job name. |
| `search` | Splunk text search. It ignores case. |
| `regex` | Splunk filter by regular expression. It respects case. |
| `strftime` | Splunk function that turns a timestamp into text. |
| `formatTimestamp` | DQL version of `strftime`. |

### Splunk to DQL

| Splunk #7 | DQL |
|---|---|
| `host="BILoss-retrieve-files-cmx-prod"` | `filter lower(host.name) == "biloss-retrieve-files-cmx-prod"` |
| `search "CMX Error"` and `regex _raw="CMX Error"` | `filter contains(content, "CMX Error")` (case-sensitive) |
| `eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")` | `fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")` |
| `table time host _raw` | `fields time, host.name, content` |

## Result

The queries are in `7-biloss-retrieve-files-cmx-error-dql.dql`: the main query and a host check.

## Data flow map

```
BILoss-retrieve-files-cmx-prod job
 → writes "CMX Error" log line
 → Dynatrace Grail
 → filter host.name → contains "CMX Error" → format time → newest first
```

## Related files

| File | Purpose |
|---|---|
| `7-biloss-retrieve-files-cmx-error-dql.dql` | Main query and host check |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Mapping details |
| `2-result.md` | How to read the result |
| `3-glossary.md` | Terms |
| `7.sh` | Git one-liners (not run) |

## Commands

See `7.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/7-biloss-retrieve-files-cmx-error-dql
git commit -m "biloss retrieve files cmx error dql"
git push
```
