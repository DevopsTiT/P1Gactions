# PayWithCreditCard DQL Final Pic

## Step map

```
earliest=-1h          → from:now()-1h
sourcetype            → startsWith(src, "portals-amp-backend")
replace x2            → replaceString if \" present
spath                 → parse raw, "JSON:j"
url=*...*             → contains(msg_url, ...)
type="..."            → msg_type == "..."
```

## Data flow

```
pod log -> Grail -> filter -> clean -> parse -> url + type -> table
```
