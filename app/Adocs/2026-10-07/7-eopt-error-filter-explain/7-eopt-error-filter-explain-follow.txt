# eopt Error Filter Explain

## Decision Tree

```
contains(content, "ERROR ", caseSensitive:false)?
 matches "error " ANYWHERE in the line, any case
   "INFO ... 0 error records" → false alert
   stack trace "...ERROR ..." in a message → false alert
 Splunk only checks the level word right after the timestamp, capitals only
   → contains(content, "Z ERROR ")        ← recommended
   → loglevel == "ERROR" if Dynatrace parses the level (cleanest)
```

## Short Takeaway

| Question | Answer |
|---|---|
| Is "ERROR " with caseSensitive:false right? | No, it is broader than Splunk |
| Why | It matches "error " anywhere in the line, in any case |
| What Splunk matches | Only the level word right after the timestamp, in capitals |
| Recommended | `contains(content, "Z ERROR ")`, case-sensitive |
| Cleanest | `loglevel == "ERROR"` if that field is filled in |

## Summary

The Splunk `rex` looks only at the start of the line: the timestamp, then the level. Its level group is `[A-Z]+`, so it only captures capital letters, and `eval upper()` changes nothing. A case-insensitive `"ERROR "` search would also catch INFO or WARN lines that just mention an error, such as "0 error records". Keeping the `Z` from the timestamp ties the match to the level position.

## Filters Compared

| Filter | What it matches | Same as Splunk? |
|---|---|---|
| `contains(content, "ERROR ", caseSensitive:false)` | "error ", "Error " or "ERROR " anywhere in the line | No, too broad |
| `contains(content, "ERROR ")` | Capital "ERROR " anywhere in the line | Close, but can match messages |
| `contains(content, "Z ERROR ")` | Capital ERROR right after the timestamp's Z | Yes |
| `loglevel == "ERROR"` | Dynatrace's parsed level field | Yes, if the field is filled in |

## Examples

| Log line | Your filter | `"Z ERROR "` | Splunk |
|---|---|---|---|
| `2026-10-06T00:30:06.693Z ERROR 1 --- [scheduling-1] ... 18 error records were found` | Match | Match | Match |
| `2026-10-06T00:30:06.693Z INFO 1 --- ... 0 error records were found` | Match | No | No |
| `2026-10-06T00:30:06.693Z WARN 1 --- ... retry after Error code 500` | No ("Error c", not "Error ") | No | No |
| `2026-10-06T00:30:06.693Z INFO 1 --- ... status=ERROR retrying` | Match | No | No |

## Recommended Query

```
fetch logs
| filter startsWith(host.name, "eopt")
| filter contains(content, "Z ERROR ")
| fieldsAdd check = "eopt_backend_error"
```

## Data Flow

```
eopt pod line → starts with "<timestamp>Z ERROR "? → yes → one medium problem → email
                                               → no (INFO/WARN mentioning error) → ignored
```

## Investigation

| Checked | Finding |
|---|---|
| Splunk rex | `^(?<timestamp>...Z)\s+(?<level>[A-Z]+)`: anchored at the line start, capitals only |
| eval upper(level) | No effect, because the level is already capitals |
| Your filter | Drops the anchor and the case, so it matches more lines |
| Check query 2 | Lists the extra lines your filter would alert on |

## Result

| Step | What to do |
|---|---|
| 1 | Use `contains(content, "Z ERROR ")` (in `7-eopt-error-filter-explain.tf`) |
| 2 | Run check.dql query 1 to compare counts |
| 3 | If `loglevel` is filled in, switch to `loglevel == "ERROR"` |

## Related Files

| File | Purpose |
|---|---|
| `7-eopt-error-filter-explain.tf` | Seq 6 detector with the case-sensitive "Z ERROR " filter |
| `7-eopt-error-filter-explain-check.dql` | Compares the filters |
| `7.sh` | Commands |
