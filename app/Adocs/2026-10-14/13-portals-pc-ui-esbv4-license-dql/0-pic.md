# Portals PC UI ESBv4 License Pic

## Decision tree

```
JSON SPL (#20, #23–#28) → unescape → parse JSON → filter fields
Metric SPL (#21) → timeseries usage / limit
License SPL (#22) → cut date → parse → < now + 100d
Phrase SPL (#29–#31) → contains
0 rows anywhere? → check query → nothing? → onboarding request
```

## Data flow

```
JSON:    pod log -> unescape -> JSON -> url/type/level -> list or count
Metric:  pc-ui CPU usage + limit -> avg per pod -> percent
License: esbv4 line -> date -> parse -> compare
Phrase:  log -> source -> phrase -> newest first
```
