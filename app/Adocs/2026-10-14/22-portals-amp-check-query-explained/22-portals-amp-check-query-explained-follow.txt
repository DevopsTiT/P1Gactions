# Portals AMP Check Query Explained

## Decision tree

```
Line 1  fetch logs, from:now()-24h          → read all logs from the last 24 hours
Line 2  filter contains(host.name, ...)     → keep lines where host name has "portals-amp"
Line 3  or contains(k8s.pod.name, ...)      →   or pod name has it
Line 4  or contains(k8s.container.name,...) →   or container name has it
Line 5  or contains(log.source, ...)        →   or log source has it
Line 6  summarize ... by:{...}              → one row per place the name was found, with a count

Result: 0 rows → the name is in none of those fields → logs not in Dynatrace (see answer 21)
Rows found → the row tells you which field to use in the real DQL
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this Splunk? | No. It is Dynatrace DQL. The Splunk query (#85) is explained in answer 20. |
| What is it for? | A "where does this app live?" check before writing the real query. |
| What does it return? | A small table: each name combination found, and how many lines. |
| What did it return? | 0 records after scanning 171 GiB. |
| What does that mean? | portals-amp logs are not in Dynatrace. |

## Summary

This query does not look for errors. It looks for the app itself. It casts a wide net (four name fields, case ignored, a full day) and then groups the hits so you can see exactly which field holds the app name. An empty result means the app's logs never arrived.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `fetch logs` | Read log records from Grail (Dynatrace storage). |
| `from:now()-24h` | Time range: from 24 hours ago until now. |
| `filter` | Keep only rows where the condition is true. |
| `contains(field, "text")` | True when the field has that text anywhere inside it. |
| `caseSensitive:false` | Ignore upper and lower case. `Portals-AMP` also matches. |
| `or` | Either condition is enough. |
| `summarize` | Group rows and calculate, like Splunk `stats`. |
| `count()` | Number of rows in each group. |
| `by:{ ... }` | The fields to group by. |

### Line by line

| Line | Code | What it does |
|---|---|---|
| 1 | `fetch logs, from:now()-24h` | Start with every log line from the last day. |
| 2 | `filter contains(host.name, "portals-amp", caseSensitive:false)` | Keep lines whose host name contains "portals-amp". App-only OneAgent pods show up here. |
| 3 | `or contains(k8s.pod.name, "portals-amp", caseSensitive:false)` | Or whose Kubernetes pod name contains it. |
| 4 | `or contains(k8s.container.name, "portals-amp", caseSensitive:false)` | Or whose container name contains it. |
| 5 | `or contains(log.source, "portals-amp", caseSensitive:false)` | Or whose log source (file path or stream) contains it. |
| 6 | `summarize lines = count(), by:{ host.name, k8s.pod.name, k8s.namespace.name, log.source, dt.openpipeline.source }` | Group what is left. Each different combination of those five fields becomes one row, with a line count. |

### Why group by those five fields

| Field | What it tells you |
|---|---|
| `host.name` | Whether the app appears as a host. |
| `k8s.pod.name` | The exact pod names. |
| `k8s.namespace.name` | The namespace. Needed for onboarding requests and filters. |
| `log.source` | Which file or stream the logs came from. |
| `dt.openpipeline.source` | How the logs entered Dynatrace (OneAgent, API ingest, and so on). |

### The same idea in Splunk

```
earliest=-24h (host="*portals-amp*" OR source="*portals-amp*" OR sourcetype="*portals-amp*")
| stats count as lines by host, source, sourcetype, index
```

| DQL | Splunk |
|---|---|
| `fetch logs, from:now()-24h` | `earliest=-24h` |
| `contains(host.name, "portals-amp", caseSensitive:false)` | `host="*portals-amp*"` (Splunk ignores case here) |
| `or` | `OR` |
| `summarize lines = count(), by:{...}` | `stats count as lines by ...` |

### How to read the result

| Result | Meaning | Next step |
|---|---|---|
| Rows found, `k8s.pod.name` filled | App is a normal Kubernetes pod in Dynatrace. | Filter the real DQL on `k8s.pod.name`. |
| Rows found, only `host.name` filled | App is seen as a host (App-only OneAgent). | Filter on `host.name`. |
| Rows found, only `log.source` filled | Logs come from a file path. | Filter on `log.source`. |
| 0 records (your case) | Name is in none of the fields. | Run checks A and B from answer 21, then onboarding request. |

## Result

Your run: 0 records, 24 hours, 171.29 GiB scanned. The query worked; the data is not there. Next steps and the request draft are in answer 21.

## Data flow map

```
All logs (24h, 171 GiB read)
  -> keep if host / pod / container / source contains "portals-amp"
  -> group by host, pod, namespace, source, ingest path
  -> count per group
  -> 0 groups → not in Dynatrace
```

## Related files

| File | What it holds |
|---|---|
| `0-pic.md` | Line tree and data flow |
| `1-investigation.md` | Line notes |
| `2-result.md` | How to read the result |
| `3-glossary.md` | Glossary |
| `22.sh` | Git one-liners |
| Answer 20 | Splunk #85 query explained |
| Answer 21 | Next checks and onboarding request |

## Commands

See `22.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/22-portals-amp-check-query-explained
git commit -m "Portals AMP check query explained"
git push
```
