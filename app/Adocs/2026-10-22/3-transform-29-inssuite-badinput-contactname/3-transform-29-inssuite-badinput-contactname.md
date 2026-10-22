# Transform 29 Inssuite BadInput ContactName

```
host like *-inssuite-prod-* + BadInputException ContactName?
 → contains host/pod "-inssuite-prod-" (caseSensitive:false)
 → contains content exception prefix (caseSensitive:false)
 → sort newest first
```

| Key point | Detail |
|---|---|
| What this is | Guidewire BadInputException when ContactName is missing/invalid |
| Splunk host | `host="*-inssuite-prod-*"` |
| Sample host | `pc2-ui-inssuite-prod-0` |

## Summary

Simple text search — no JSON parse. Match inssuite-prod hosts/pods and the BadInputException ContactName line.

## Splunk (source)

```
host="*-inssuite-prod-*" "gw.api.rest.exceptions.BadInputException: ContactName:"
```

## DQL (live)

```
fetch logs, from:now()-24h
| filter contains(host.name, "-inssuite-prod-", caseSensitive:false)
    or contains(k8s.pod.name, "-inssuite-prod-", caseSensitive:false)
| filter contains(content, "gw.api.rest.exceptions.BadInputException: ContactName:", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, content
```

Optional tighter match using your sample Japanese text:

```
| filter contains(content, "gw.api.rest.exceptions.BadInputException: ContactName:", caseSensitive:false)
    and contains(content, "これは必須フィールドです", caseSensitive:false)
```

## Verify dummy

```
fetch logs
| limit 1
| fieldsAdd dummy = "gw.api.rest.exceptions.BadInputException: ContactName: これは必須フィールドです"
| fieldsAdd host_name = "pc2-ui-inssuite-prod-0"
| fields dummy, host_name
| filter contains(host_name, "-inssuite-prod-", caseSensitive:false)
| filter contains(dummy, "gw.api.rest.exceptions.BadInputException: ContactName:", caseSensitive:false)
| fields host_name, dummy
```

**Pass:** one row with the exception text.

## Splunk → DQL

| Splunk | DQL |
|---|---|
| `host="*-inssuite-prod-*"` | `contains(host.name, "-inssuite-prod-", caseSensitive:false)` (also pod) |
| quoted exception string | `contains(content, "...ContactName:", caseSensitive:false)` |

## Data flow map

```
logs (24h)
  → host/pod contains -inssuite-prod-
  → content contains BadInputException: ContactName:
  → sort desc → fields
```

## Related files

| File | Role |
|---|---|
| `3-transform-29-inssuite-badinput-contactname.dql` | Live + verify |
| `3.sh` | Dual-write |

## Commands

See [3.sh](3.sh).
