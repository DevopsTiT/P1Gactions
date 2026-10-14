# Splunk Internal Mailservice Hosts DQL

## Decision tree

```
Which SPL?
 #14 license usage (index=_internal)
   → Splunk-only data → use log text size per day in DQL
   need exact billed volume? → run billing-events check query
 #15 / #16 index=mailservice
   → Dynatrace has no "index" → filter by host, namespace, or bucket
   0 rows? → run mailservice check query → keep the field that matches
   still 0? → logs not in Dynatrace → onboarding request
 #17 metrics.log throughput (index=_internal)
   → Splunk-only data → count log lines per minute per source, top 5
 #18 metadata type=hosts (silent hosts)
   → last log time per host → keep hosts silent > 1 hour
   heavy query? → shorten from:now()-7d to now()-2d
```

## Short takeaway

| SPL | What it does | DQL approach |
|---|---|---|
| #14 | Daily license bytes by pool, source, sourcetype, host, index | Sum of `stringLength(content)` per day |
| #15 | Finds `AuthenticationFailedException` in mailservice | `contains(..., caseSensitive:false)` |
| #16 | Finds Tomcat "Catalina.start Server startup" in mailservice | `matchesPhrase()` |
| #17 | Events per minute, top 5 sources | `makeTimeseries count()` then top 5 |
| #18 | Prod hosts that stopped logging more than 1 hour ago | `max(timestamp)` per host |

## Summary

#15 and #16 are normal log searches. #14, #17 and #18 read Splunk's own internal data (license and throughput logs, host metadata). Dynatrace does not store that data, so each one is rebuilt from the log records themselves. The results are close, but not exactly the same numbers Splunk reports.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `index` | Splunk storage bucket. Dynatrace has no direct equal. The closest is `dt.system.bucket`. |
| `_internal` | Splunk's own logs about itself. Not present in Dynatrace. |
| `license_usage.log` | Splunk file that records ingested bytes. |
| `metrics.log` | Splunk file that records throughput. |
| `metadata type=hosts` | Splunk command listing each host with first and last event time. |
| `makeTimeseries` | DQL command that builds a chart over time. Same idea as Splunk `timechart`. |
| `stringLength()` | Number of characters in a text field. |

### SPL #14 mapping

| Splunk piece | DQL piece | Note |
|---|---|---|
| `b` (bytes) | `stringLength(content)` | Approximation. Only counts the log text. |
| `pool` | No equivalent | Splunk license pools do not exist in Dynatrace. Dropped. |
| `s` (source) | `log.source` | |
| `st` (sourcetype) | `dt.openpipeline.source` | Closest available field. |
| `h` (host) | `host.name` | |
| `idx` (index) | `dt.system.bucket` | |
| `if(len(x)=0 OR isnull(x), "(SQUASHED)", x)` | `coalesce(x, "(SQUASHED)")` | Fills in empty values. |
| `bin _time span=1d` | `bin(timestamp, 1d)` | |
| `stats sum(b) by ...` | `summarize b = sum(b), by:{...}` | |

### SPL #15 and #16 mapping

| Splunk piece | DQL piece | Note |
|---|---|---|
| `index=mailservice` | Host, namespace, or bucket contains `mailservice` | Placeholder. Confirm with the check query. |
| `"*AuthenticationFailedException*"` | `contains(content, "AuthenticationFailedException", caseSensitive:false)` | The `*` wildcards mean substring. |
| `"Catalina.start Server startup"` | `matchesPhrase(content, "Catalina.start Server startup")` | Quoted phrase, case ignored. |

### SPL #17 mapping

| Splunk piece | DQL piece | Note |
|---|---|---|
| `group=per_source_thruput` | `by:{ log.source }` | Splunk measures per source. DQL groups by source. |
| `NOT filetracker` | Not needed | That is a Splunk internal source. |
| `eval events=eps*kb/kbps` | `count()` | Splunk works out the event count. DQL counts directly. |
| `timechart span=1m` | `makeTimeseries ..., interval:1m` | |
| `limit=5` | `sort total desc` then `limit 5` | |

### SPL #18 mapping

| Splunk piece | DQL piece | Note |
|---|---|---|
| `metadata type=hosts` | `summarize min(timestamp), max(timestamp), count() by host.name` | |
| `Last_Seen=now()-recentTime` | `(toLong(now()) - toLong(last_event)) / 1000000000` | Seconds since last log. |
| `where Last_Seen > 3600` | `filter last_seen_sec > 3600` | Silent for more than 1 hour. |
| `strftime(..., "%c")` | `formatTimestamp(..., format:"EEE MMM dd HH:mm:ss yyyy")` | |
| `round(Last_Seen/60, 0)` | `round(toDouble(x) / 60, decimals:0)` | |
| `like(host, "%-prod-%")` | `contains(host.name, "-prod-")` | |
| `NOT like(host, "%amazonaws%")` | `not contains(host.name, "amazonaws")` | |

## Result

All queries are in `11-splunk-internal-mailservice-hosts-dql.dql`.

### #14

```
fetch logs, from:now()-7d
| fieldsAdd b = stringLength(content)
| fieldsAdd s   = coalesce(log.source, "(SQUASHED)"),
            st  = coalesce(dt.openpipeline.source, "(SQUASHED)"),
            h   = coalesce(host.name, "(SQUASHED)"),
            idx = coalesce(dt.system.bucket, "(UNKNOWN)")
| summarize b = sum(b), by:{ day = bin(timestamp, 1d), s, st, h, idx }
| fieldsAdd gb = round(toDouble(b) / 1073741824, decimals:3)
| sort day desc, b desc
```

### #15

```
fetch logs, from:now()-24h
| filter contains(host.name, "mailservice", caseSensitive:false)
    or contains(k8s.namespace.name, "mailservice", caseSensitive:false)
    or contains(dt.system.bucket, "mailservice", caseSensitive:false)
| filter contains(content, "AuthenticationFailedException", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, log.source, content
```

### #16

```
fetch logs, from:now()-24h
| filter contains(host.name, "mailservice", caseSensitive:false)
    or contains(k8s.namespace.name, "mailservice", caseSensitive:false)
    or contains(dt.system.bucket, "mailservice", caseSensitive:false)
| filter matchesPhrase(content, "Catalina.start Server startup")
| sort timestamp desc
| fields timestamp, host.name, log.source, content
```

### #17

```
fetch logs, from:now()-1h
| makeTimeseries events = count(), by:{ log.source }, interval:1m
| fieldsAdd total = arraySum(events)
| sort total desc
| limit 5
```

### #18

```
fetch logs, from:now()-7d
| filter contains(host.name, "-prod-") and not contains(host.name, "amazonaws")
| summarize count = count(), first_event = min(timestamp), last_event = max(timestamp), by:{ host.name }
| fieldsAdd last_seen_sec = (toLong(now()) - toLong(last_event)) / 1000000000
| filter last_seen_sec > 3600
| fieldsAdd minutes_behind = round(toDouble(last_seen_sec) / 60, decimals:0),
            hours_behind   = round(toDouble(last_seen_sec) / 3600, decimals:1),
            days_behind    = round(toDouble(last_seen_sec) / 86400, decimals:1),
            last_event_jst = formatTimestamp(last_event, format:"EEE MMM dd HH:mm:ss yyyy", timezone:"Asia/Tokyo")
| sort last_seen_sec desc
| fields host.name, last_event_jst, minutes_behind, hours_behind, days_behind
```

## Data flow map

```
#14  Grail logs -> text size per line -> fill empty labels -> sum per day per source/host/bucket
#15  Grail logs -> mailservice -> "AuthenticationFailedException" -> newest first
#16  Grail logs -> mailservice -> "Catalina.start Server startup" -> newest first
#17  Grail logs (1h) -> count per minute per source -> top 5 sources -> chart
#18  Grail logs (7d) -> prod hosts, not amazonaws -> last log time per host
                    -> seconds since last log > 3600 -> minutes / hours / days behind
```

## Related files

| File | What it holds |
|---|---|
| `11-splunk-internal-mailservice-hosts-dql.dql` | All five queries and check queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Mapping notes |
| `2-result.md` | Final DQL |
| `3-glossary.md` | Glossary |
| `11.sh` | Git one-liners |

## Commands

See `11.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/11-splunk-internal-mailservice-hosts-dql
git commit -m "Splunk internal, mailservice, silent hosts DQL"
git push
```
