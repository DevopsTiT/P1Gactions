# Alfresco Pod Or Host DQL

```
Splunk Message
  one name per event, from the host field
  Message = how many different names
  Message is 4 → no output row
Dynatrace name for the same check
  pod name contains alfrescoacr-batch → use k8s.pod.name
  else host name contains it → use host.name
  log.source can find the line
  Message = how many different units
  Message is 4 → no output row
```

| Key point | Detail |
|---|---|
| Splunk check | Distinct `host` values in `alfrescoacr-batch`. Quiet when the count is 4. |
| Name fields | `k8s.pod.name` and `host.name`. |
| Which name is kept | Pod name when that field matches. Otherwise the host name. |
| `Message` | How many different names. It is not the log-line count. |
| Quiet result | No row when `Message` is 4. |

## Summary

Use one name per log line. Take `k8s.pod.name` when that field contains `alfrescoacr-batch`. Otherwise take `host.name` when that field contains it. `log.source` can also find the line. `Message` is how many different names that produces. The query returns a row only when `Message` is not 4.

## Investigation

| Source | Finding |
|---|---|
| Splunk | `stats count by host`, drop `count`, then `Message` is the number of host rows. `where NOT Message=4`. |
| Screen DQL | `coalesce(k8s.pod.name, host.name)`, then `summarize total = count(), by:{ host }`, then `filter total != 4`. |
| What `count()` is there | Log lines for each name. |
| What Splunk `Message` is | The number of names. |
| Host page name | `alfrescoacr-batch-innsuite-prod-0`. That string can sit in the pod field or the host field in app-only mode. |

`coalesce` keeps the pod name whenever the pod field is filled, even when the app name is only in `host.name`. The rewritten query tests both fields.

## Result

Set the time picker to the same window as the Splunk search before you compare. That window was 10/28/2026 1:00 PM through 10/29/2026 1:43 PM.

Alert query. One row only when the name count is not 4:

```
fetch logs
| filter contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false)
    or contains(host.name, "alfrescoacr-batch", caseSensitive:false)
    or contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "alfrescoacr-batch", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 4
| fields host, Message
```

| Piece | What it means |
|---|---|
| Three `contains` checks | A line qualifies from the pod name, the host name, or the log source. |
| `from_pod` | The pod name, only when that field contains `alfrescoacr-batch`. |
| `from_host` | The host name, only when that field contains `alfrescoacr-batch`. |
| `coalesce(from_pod, from_host)` | Pod name when it matches. Otherwise the host name. |
| `countDistinct(unit)` | How many different names. This is `Message`. |
| `Message != 4` | Drop the row when the count is 4. |

0 records means 4 names. That is the same quiet result as Statistics (0).

List query. Run this to see the names:

```
fetch logs
| filter contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false)
    or contains(host.name, "alfrescoacr-batch", caseSensitive:false)
    or contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "alfrescoacr-batch", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize log_count = count(), by: { unit, k8s.pod.name, host.name }
| sort unit asc
```

`log_count` is how many lines each name wrote. The alert ignores `log_count`. A line whose pod name and host name are both empty is not counted as a name.

When the pod name and the host name are two different strings for the same workload, `coalesce` keeps the pod name. Read the list. The `unit` column is what `Message` counts.

## Data flow map

```
log line
        |
        +--> k8s.pod.name contains alfrescoacr-batch → from_pod
        +--> host.name contains alfrescoacr-batch → from_host
        +--> log.source contains alfrescoacr-batch → line is eligible
        |
        v
unit = pod name if it matched, else host name
        |
        v
Message = countDistinct(unit)
        |
        +-- Message is 4 → no row
        +-- Message is not 4 → host Total, Message = that count
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the screen query counts. |
| `2-result.md` | The DQL to paste. |
| `3-glossary.md` | Terms. |
| `15-alfresco-pod-or-host-dql-follow.txt` | Same DQL for mobile. |
| `15.sh` | Copy commands. |

Commands: [15.sh](15.sh)
