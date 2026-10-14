# Error Access And PC2 UI Claims DQL

## Decision tree

```
Which SPL?
 #11 or #12 (same text) → word search: error, failed, severe, or access log with 404/500/503
   0 rows on the access part? → run the "access" check query → put the right field in place of log.source
   too many rows? → add a host or app filter first (Splunk searched every default index)
 #13 (pc2-ui + claims URL + FAIL)
   0 rows? → run the "pc2-ui" check query
     found in k8s.pod.name or k8s.container.name? → keep that filter, drop the others
     nothing found? → pc2 logs may only go to S3 / Splunk → onboarding request (like eopt)
```

## Short takeaway

| Question | Answer |
|---|---|
| Are #11 and #12 different? | No. Same text, so one DQL covers both. |
| Splunk bare word like `error` | DQL `matchesPhrase(content, "error")` |
| Why not `contains()` for bare words? | Splunk matches whole words. `contains()` would also match `errors` or `terror`. |
| Splunk `sourcetype=` | No direct Dynatrace field. Usually `log.source`, pod name, or container name. Check first. |
| #13 URL | Matched in two safe pieces: the host part and the path part. |
| #13 `FAIL` | `matchesPhrase(content, "FAIL")`, case ignored like Splunk. |

## Summary

SPL #11/#12 is a broad error-word search plus a status-code search on access logs. SPL #13 finds pc2-ui lines that call the legacy claims ESB endpoint and contain FAIL. The one piece that cannot be copied directly is `sourcetype`, because that is a Splunk-only label. Use the check queries to see which Dynatrace field holds it.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| sourcetype | A Splunk label for the log format. Dynatrace does not have it. |
| `log.source` | Dynatrace field for where the log came from, often a file path or stream name. |
| `matchesPhrase()` | Matches whole words, ignoring case. Closest to a Splunk bare search term. |
| `contains()` | Matches any substring. Case-sensitive unless you add `caseSensitive:false`. |
| `http.response.status_code` | Parsed HTTP status field, present only if a parsing rule creates it. |

### SPL #11 / #12 mapping

| Splunk piece | DQL piece | Why |
|---|---|---|
| `error` | `matchesPhrase(content, "error")` | Whole word, case ignored, like Splunk. |
| `failed` | `matchesPhrase(content, "failed")` | Same rule. |
| `severe` | `matchesPhrase(content, "severe")` | Same rule. |
| `OR` | `or` | Same meaning. |
| `sourcetype=access_*` | `startsWith(log.source, "access_")` | Placeholder. Confirm the real field with the check query. |
| `(404 OR 500 OR 503)` | `matchesPhrase(content, "404")` and so on | Splunk searches the raw text for these numbers. |
| No index given | Add `from:now()-1h` and, ideally, a host filter | An unscoped search over all logs is expensive. |

### SPL #13 mapping

| Splunk piece | DQL piece | Why |
|---|---|---|
| `sourcetype="pc2-ui"` | `log.source`, `k8s.container.name`, or `k8s.pod.name` contains `pc2-ui` | Placeholder. Confirm with the check query. |
| `"https://esbv4-...claims"` | Two `contains()` checks: host part and path part | Avoids typos in the long URL. Note that `op-prod-lpl` in the screenshot could be `lpl` or `1p1`. |
| `FAIL` | `matchesPhrase(content, "FAIL")` | Splunk bare term, whole word, case ignored. |

## Result

### SPL #11 and #12

```
fetch logs, from:now()-1h
| filter matchesPhrase(content, "error")
    or matchesPhrase(content, "failed")
    or matchesPhrase(content, "severe")
    or (
         startsWith(log.source, "access_")
         and (matchesPhrase(content, "404") or matchesPhrase(content, "500") or matchesPhrase(content, "503"))
       )
| sort timestamp desc
| fields timestamp, host.name, log.source, loglevel, content
```

### SPL #13

```
fetch logs, from:now()-24h
| filter contains(log.source, "pc2-ui", caseSensitive:false)
    or contains(k8s.container.name, "pc2-ui", caseSensitive:false)
    or startsWith(k8s.pod.name, "pc2-ui")
| filter contains(content, "esbv4-inssuite-prod", caseSensitive:false)
    and contains(content, "/esb/legacyclaims/services/legacydata/claims", caseSensitive:false)
| filter matchesPhrase(content, "FAIL")
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, log.source, content
```

The status-code variant and both check queries are in `10-error-access-pc2-ui-claims-dql.dql`.

## Data flow map

```
#11 / #12
All logs (Grail)
  -> filter: word error / failed / severe
     OR (access log AND 404 / 500 / 503)
  -> sort newest first
  -> table

#13
pc2-ui logs (Grail)
  -> filter: source is pc2-ui
  -> filter: line has ESB host AND legacy claims path
  -> filter: word FAIL
  -> sort newest first
  -> table
```

## Related files

| File | What it holds |
|---|---|
| `10-error-access-pc2-ui-claims-dql.dql` | Main queries, status-code variant, check queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Mapping details |
| `2-result.md` | Final DQL |
| `3-glossary.md` | Glossary |
| `10.sh` | Git one-liners |

## Commands

See `10.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/10-error-access-pc2-ui-claims-dql
git commit -m "Error access and pc2-ui claims DQL"
git push
```
