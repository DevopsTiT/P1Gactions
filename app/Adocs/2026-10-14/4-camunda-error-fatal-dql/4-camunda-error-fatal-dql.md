# Camunda Error Fatal DQL

## Decision tree

```
Splunk → DQL
 sourcetype="camunda-platform"        → no sourcetype in Dynatrace → host prefixes are enough
 host="camunda8-prod-identity-*" ...  → startsWith on host.name or k8s.pod.name
   zeebe-* already covers zeebe-gateway-* → 3 prefixes, not 4
 search ("ERROR" OR "FATAL")          → case insensitive in Splunk
 mvappend(if(match(...)))             → case sensitive
 where isnotnull(matched_keywords)    → drops lowercase-only lines
   → net result: case sensitive ERROR or FATAL → contains() without caseSensitive:false
 strftime, table                      → formatTimestamp, fields
 empty? → check 1 → which field holds camunda8 names
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it find? | Lines with uppercase ERROR or FATAL from Camunda 8 identity, Zeebe, Zeebe gateway and Keycloak pods. |
| Why only 3 prefixes? | `camunda8-prod-zeebe-` already matches `camunda8-prod-zeebe-gateway-`. |
| Case | Final result is case sensitive, so DQL uses plain `contains()`. |
| `where isnotnull` | Not needed in DQL. The filter already keeps only lines with a keyword. |
| Risk | Pod names may sit in `k8s.pod.name`, not `host.name`. The filter checks both. |

## Summary

The search picks error lines from four Camunda 8 components and tags each line with ERROR, FATAL or both. Splunk first matches any case, then the `match()` and `isnotnull` steps remove lines that only have lowercase "error". So the real rule is uppercase ERROR or FATAL, and the DQL filters that way from the start.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Camunda 8 | A workflow engine platform. | The system being searched. |
| Zeebe | Camunda 8's workflow engine (brokers). | Main source of process errors. |
| Zeebe gateway | Entry point that clients call to reach Zeebe. | Shows connection and request errors. |
| Identity | Camunda 8's user and permission service. | Login and token errors. |
| Keycloak | Login server that Identity uses. | Authentication errors. |
| `sourcetype` | Splunk label for a log format. | Dynatrace has no sourcetype, so the host prefixes do the job. |
| `isnotnull` | True when a field has a value. | Here it removes lines with no uppercase keyword. |

### Why the result is case sensitive

| Step | Line `ERROR timeout` | Line `error timeout` |
|---|---|---|
| `search ("ERROR" OR "FATAL")` (any case) | Kept | Kept |
| `match(_raw, "ERROR")` (case sensitive) | Yes, adds "ERROR" | No |
| `matched_keywords` | ["ERROR"] | Empty |
| `where isnotnull(matched_keywords)` | Kept | Dropped |

### Splunk to DQL

| Splunk | DQL | Note |
|---|---|---|
| `sourcetype="camunda-platform"` | Not needed. | Host prefixes already limit it to Camunda pods. |
| `host="camunda8-prod-identity-*"` | `startsWith(host.name, "camunda8-prod-identity-")` | Also checked on `k8s.pod.name`. |
| `host="camunda8-prod-zeebe-*"` | `startsWith(host.name, "camunda8-prod-zeebe-")` | Also covers the gateway. |
| `host="camunda8-prod-zeebe-gateway-*"` | Covered by the line above. | |
| `host="camunda8-prod-keycloak-*"` | `startsWith(host.name, "camunda8-prod-keycloak-")` | |
| `search ("ERROR" OR "FATAL")` plus `where isnotnull(...)` | `filter contains(content, "ERROR") or contains(content, "FATAL")` | Case sensitive. |
| `eval matched_keywords=mvappend(...)` | `arrayRemoveNulls(array(if(...), if(...)))` | |
| `eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")` | `formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")` | |
| `table time host matched_keywords _raw` | `fields time, host.name, k8s.pod.name, matched_keywords, content` | |

## Result

```
fetch logs, from:now()-24h
| filter startsWith(host.name, "camunda8-prod-identity-")
    or startsWith(host.name, "camunda8-prod-zeebe-")
    or startsWith(host.name, "camunda8-prod-keycloak-")
    or startsWith(k8s.pod.name, "camunda8-prod-identity-")
    or startsWith(k8s.pod.name, "camunda8-prod-zeebe-")
    or startsWith(k8s.pod.name, "camunda8-prod-keycloak-")
| filter contains(content, "ERROR") or contains(content, "FATAL")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "ERROR"), "ERROR"),
    if(contains(content, "FATAL"), "FATAL")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, k8s.pod.name, matched_keywords, content
```

### Example output row

| time | host.name | matched_keywords | content |
|---|---|---|---|
| 2026-10-14 09:35:02 JST | camunda8-prod-zeebe-gateway-6c9f-xk2lp | ["ERROR"] | `ERROR io.camunda.zeebe.gateway ... DEADLINE_EXCEEDED` |

### If it returns 0

| Check 1 shows | Meaning | Change |
|---|---|---|
| Names in `k8s.pod.name` | Already covered. | None. |
| Names in another field, such as `k8s.workload.name` | Pods named differently in Dynatrace. | Use that field in the filter. |
| Namespace only, for example `camunda` | Filter by namespace. | `filter k8s.namespace.name == "<namespace>"` |
| Nothing | Camunda logs are not in Dynatrace. | Use the missing logs logic from 2026-10-13 answer 3. |

The `.dql` file also has a count per component (identity, zeebe, zeebe-gateway, keycloak) and keyword.

## Data flow map

```
Camunda 8 pods (identity, zeebe, zeebe-gateway, keycloak)
  → Dynatrace Grail logs ? (check 1)
  → fetch logs, last 24 h
  → keep camunda8-prod-identity-*, -zeebe-*, -keycloak-* (host.name or k8s.pod.name)
  → keep lines with uppercase ERROR or FATAL
  → tag each line with ERROR, FATAL or both
  → JST time → newest first → time, host, pod, keywords, line
```

## Related files

| File | What it holds |
|---|---|
| `4-camunda-error-fatal-dql.dql` | Main query, check and count per component. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Stage mapping. |
| `2-result.md` | Final query and empty-result guide. |
| `3-glossary.md` | Words used. |
| `4.sh` | Git one-liners. |
| `Daily Files/2026-10-14/1-envelope-exception-spl-to-dql/` | Same pattern with more keywords. |

## Commands

Run the queries in a Dynatrace Notebook. Git one-liners are in [`4.sh`](./4.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/4-camunda-error-fatal-dql
git commit -m "Camunda error fatal DQL"
git push
```
