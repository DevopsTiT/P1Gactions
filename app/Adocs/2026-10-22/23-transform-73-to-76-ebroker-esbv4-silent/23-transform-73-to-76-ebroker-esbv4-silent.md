# Transform 73 To 76 Ebroker ESBv4 Silent

```
#73 ebroker + Started: POST /request/nttif?  (was blurry ottif → nttif)
#74 esbv4 + pc quote failed URL (op-prod-jp1)?
#75 esbv4 + Error sending HTTP request to localhost:8083?  (was 8082)
#76 apps silent > 1 hour (metadata → summarize by app)?
```

| Key point | Detail |
|---|---|
| #73 update | Phrase is `nttif` (log sample shows `/request/nttif/auto`) |
| #74 update | Host segment is `op-prod-jp1` (not `op-prod-lpl`) |
| #75 update | Port is `8083` (not `8082`) |
| #76 | No Splunk `metadata` in DQL — summarize last log per app over 7d |

## Summary

**73–75** match the updated drafts, with `log.source` fallbacks and `caseSensitive:false`. **76** turns Splunk sourcetype freshness into “last log per app name” and keeps apps quiet longer than one hour.

---

## #73 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "ebroker")
    or contains(log.source, "ebroker", caseSensitive:false)
| filter contains(content, "Started: POST /request/nttif", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #74 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "esbv4")
    or contains(log.source, "esbv4", caseSensitive:false)
| filter contains(content, "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-jp1.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: ", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #75 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "esbv4")
    or contains(log.source, "esbv4", caseSensitive:false)
| filter contains(content, "Error sending HTTP request to http://localhost:8083", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #76 DQL (live)

```
fetch logs, from:now()-7d
| fieldsAdd app = lower(coalesce(k8s.workload.name, k8s.container.name, host.name, log.source))
| filter matchesValue(app, array("agrex*", "alfresco*", "bcsubledger*", "ebroker*", "esbv4*", "jobscheduler*",
                                 "legacybridge*", "mailservice*", "portals*", "tts"))
| filter not in(app, array("ebroker_batch", "alfrescoaev", "portals-claim-vendor-backend", "portals-claim-vendor-frontend"))
| summarize count = count(), first_event = min(timestamp), last_event = max(timestamp), by:{ app }
| fieldsAdd last_seen_sec = (toLong(now()) - toLong(last_event)) / 1000000000
| filter last_seen_sec > 3600
| fieldsAdd minutes_behind = round(toDouble(last_seen_sec) / 60, decimals:0),
            hours_behind   = round(toDouble(last_seen_sec) / 3600, decimals:1),
            days_behind    = round(toDouble(last_seen_sec) / 86400, decimals:1),
            last_event_jst = formatTimestamp(last_event, format:"EEE MMM dd HH:mm:ss yyyy", timezone:"Asia/Tokyo")
| sort minutes_behind desc
| fields app, last_event_jst, minutes_behind, hours_behind, days_behind
```

## Data flow map

```
#73: ebroker → Started: POST /request/nttif
#74: esbv4 → esb-ebroker.xml → pc …/ebroker/quote failed: …
#75: esbv4 → Error sending HTTP request to http://localhost:8083
#76: 7d logs → app name → last_event → silent > 3600s → minutes/hours/days behind
```

## Related files

| File | Role |
|---|---|
| `23-transform-73-to-76-ebroker-esbv4-silent.dql` | Live + verify |
| `23.sh` | Dual-write |

## Commands

See [23.sh](23.sh).
