# Alfresco DQL Review

```
Prod_PnC_Alfrescoacr_BatchPODFrozen_High
  Splunk Message = number of hosts
  Message is 4 → no row
  DQL on the screen
    total = count() by name → log lines per name
    filter total != 4 → names that did not write exactly 4 lines
  that is a different check
  use countDistinct of pod name or host name
  return one Total row only when that count is not 4
```

| Key point | Detail |
|---|---|
| Alert name | `Prod_PnC_Alfrescoacr_BatchPODFrozen_High`. |
| Splunk result | One row, `host` = `Total`, `Message` = how many hosts. Kept only when that is not 4. |
| Screen DQL | Many rows. `total` is log lines for each name. Kept when that line count is not 4. |
| Verdict | This DQL does not match the Splunk alert. |

## Summary

The DQL on the screen is not the same check. Splunk counts names and stays quiet when there are 4. The DQL counts log lines for each name and keeps every name that did not write exactly 4 lines. With four busy pods, Splunk returns nothing and this DQL returns four rows.

## Investigation

| Source | Finding |
|---|---|
| Splunk | `stats count by host`, drop `count`, `appendpipe` sets `Message` to the number of host rows, keep the row when `Message` is not 4. |
| DQL line 13 | `host = coalesce(k8s.pod.name, host.name)`. A filled pod name hides `host.name`. |
| DQL line 16 | `summarize total = count(), by:{ host }`. `total` is log lines. |
| DQL line 17 | `filter total != 4`. Applied to each name’s line count. |
| DQL line 18 | Output is `host, total`. Splunk’s output is one `Total` row and `Message`. |

## Result

Paste this in place of lines 12–18. It uses the pod name when `k8s.pod.name` contains `alfrescoacr-batch`, otherwise the host name.

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

0 records means `Message` is 4. That matches a quiet Splunk result.

| Screen piece | What it does |
|---|---|
| `coalesce(k8s.pod.name, host.name)` | Keeps the pod name whenever that field is filled. |
| `total = count()` | Counts log lines for one name. |
| `filter total != 4` | Keeps names whose line count is not 4. |
| `fields host, total` | One output row per such name. |

## Data flow map

```
Splunk
  events → one row per host → Message = how many hosts
        |
        +-- Message is 4 → no row
        +-- Message is not 4 → one Total row

Screen DQL
  events → group by coalesced name → total = log lines
        |
        +-- that name wrote 4 lines → drop the name
        +-- that name wrote any other number → keep the name
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Line-by-line reading of the screen DQL. |
| `2-result.md` | The replacement query. |
| `3-glossary.md` | Terms. |
| `16-alfresco-dql-review-follow.txt` | Same review for mobile. |
| `16.sh` | Copy commands. |

Commands: [16.sh](16.sh)
