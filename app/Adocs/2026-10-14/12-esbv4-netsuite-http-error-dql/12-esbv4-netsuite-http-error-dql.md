# ESBv4 NetSuite HTTP Error DQL

## Decision tree

```
Run the main DQL
 rows returned? → ESB failed to reach NetSuite → check time pattern with the 5-minute chart
   burst at one time? → NetSuite outage or network blip
   steady all day? → auth, certificate, or config problem on the ESB side
 0 rows?
   → run esbv4 check query
     found in pod or namespace? → keep that filter only
     nothing found? → esbv4 logs not in Dynatrace → onboarding request
   → try the phrase without ":443" in case the log prints the URL differently
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the SPL do? | Finds ESBv4 lines saying it could not send an HTTP request to NetSuite. |
| `index=esbv4` in DQL | No index in Dynatrace. Filter host, namespace, pod, or bucket for `esbv4`. |
| Quoted phrase in DQL | `contains(content, "...", caseSensitive:false)` |
| Why `caseSensitive:false`? | Splunk phrase search ignores case. |

## Summary

This is a single-phrase search. The only part that needs care is `index=esbv4`, because Dynatrace does not have indexes. Run the check query once to see which field holds `esbv4`, then keep just that filter.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| ESBv4 | Enterprise Service Bus version 4. The middle layer that calls other systems. |
| NetSuite RESTlet | A small API endpoint hosted in NetSuite (an ERP system). |
| `:443` | The HTTPS port. |
| `index` | Splunk storage area. No direct Dynatrace equal. |
| `contains()` | True when the text appears in the field. |

### Mapping

| Splunk piece | DQL piece | Why |
|---|---|---|
| `index=esbv4` | `esbv4` in host, namespace, pod, or bucket | Placeholder. Confirm with the check query. |
| `"Error sending HTTP request to https://...:443"` | `contains(content, "...", caseSensitive:false)` | Quoted phrase, case ignored like Splunk. |
| (no time) | `from:now()-24h` | Pick a window. |

## Result

```
fetch logs, from:now()-24h
| filter contains(host.name, "esbv4", caseSensitive:false)
    or contains(k8s.namespace.name, "esbv4", caseSensitive:false)
    or contains(k8s.pod.name, "esbv4", caseSensitive:false)
    or contains(dt.system.bucket, "esbv4", caseSensitive:false)
| filter contains(content, "Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, log.source, content
```

Check query:

```
fetch logs, from:now()-24h
| filter contains(host.name, "esbv4", caseSensitive:false)
    or contains(k8s.namespace.name, "esbv4", caseSensitive:false)
    or contains(k8s.pod.name, "esbv4", caseSensitive:false)
    or contains(log.source, "esbv4", caseSensitive:false)
    or contains(dt.system.bucket, "esbv4", caseSensitive:false)
| summarize lines = count(), by:{ host.name, k8s.namespace.name, k8s.pod.name, log.source, dt.system.bucket }
| sort lines desc
```

Error count per 5 minutes:

```
fetch logs, from:now()-24h
| filter contains(content, "Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443", caseSensitive:false)
| makeTimeseries errors = count(), interval:5m
```

## Data flow map

```
ESBv4 app
  -> tries HTTPS call to NetSuite RESTlet (port 443)
  -> call fails -> writes "Error sending HTTP request to ..."
  -> Dynatrace Grail (fetch logs)
  -> filter: esbv4 source
  -> filter: error phrase (case ignored)
  -> newest first -> table
```

## Related files

| File | What it holds |
|---|---|
| `12-esbv4-netsuite-http-error-dql.dql` | Main, check, and chart queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Mapping notes |
| `2-result.md` | Final DQL |
| `3-glossary.md` | Glossary |
| `12.sh` | Git one-liners |

## Commands

See `12.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/12-esbv4-netsuite-http-error-dql
git commit -m "ESBv4 NetSuite HTTP error DQL"
git push
```
