# Transform 71 72 Ebroker ApiMain ESBv4 Lookup

```
#70 already in seq 16 (address conversion) — matches your draft
#71 ebroker + Starting ApiMain on ebroker?
#72 esbv4 Interceptor exception whose UUID was in Sending request to /esb/ebroker?
 → parse UUID both sides → lookup on query → keep when req.query is set
```

| Key point | Detail |
|---|---|
| #71 | Simple phrase; one hit ≈ one restart |
| #72 | Splunk subsearch + `format` → DQL `lookup` |
| UUID | Same parse on exception lines and on send-request lines |
| #70 note | Your draft matches seq 16 (no space after `failed.`) |

## Summary

**71** is ebroker startup. **72** keeps Interceptor exception lines only when that request UUID also appears on a prior “Sending request to /esb/ebroker” line.

---

## #71 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "ebroker")
    or contains(log.source, "ebroker", caseSensitive:false)
| filter contains(content, "Starting ApiMain on ebroker", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #71 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-20 17:14:39.076 INFO 1 --- [main] j.a.e.ApiMain : Starting ApiMain on ebroker-0 with PID 1"
| fieldsAdd pod = "ebroker-api-5b7c9d8f6-q8w2r"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "ebroker")
| filter contains(dummy, "Starting ApiMain on ebroker", caseSensitive:false)
| fields src, dummy
```

---

## #72 DQL (live)

Outer side: Interceptor exceptions + parse UUID.  
Lookup side: “Sending request to /esb/ebroker” + parse UUID.  
Keep rows where the lookup found a match (`req.query` not null).

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "esbv4")
    or contains(log.source, "esbv4", caseSensitive:false)
| filter contains(content, "Interceptor for", caseSensitive:false)
    and contains(content, "has thrown exception", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
    | filter startsWith(src, "esbv4")
        or contains(log.source, "esbv4", caseSensitive:false)
    | filter contains(content, "Sending request to /esb/ebroker", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"req."
| filter isNotNull(req.query)
| sort timestamp desc
| fields timestamp, src, query, content
```

## #72 verify (shape only — lookup needs two real log families)

Dummy checks that the exception phrase + UUID parse work. Run live #72 against real esbv4 logs for the join.

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-20 17:15:01.234 ERROR Interceptor for {http://esb}ebroker has thrown exception, unwinding now - ID a1b2c3d4-e5f6-7890-abcd-ef1234567890"
| fieldsAdd pod = "esbv4-7c9d8b6f5-k2m4p"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "esbv4")
| filter contains(dummy, "Interceptor for", caseSensitive:false)
    and contains(dummy, "has thrown exception", caseSensitive:false)
| parse dummy, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| fields src, query, dummy
```

## Data flow map

```
#71: ebroker → Starting ApiMain on ebroker → restart signal

#72:
  A) esbv4 + Interceptor for … has thrown exception → parse UUID as query
  B) esbv4 + Sending request to /esb/ebroker → parse UUID as query (lookup table)
  A lookup B on query → keep when req.query is set
```

## Related files

| File | Role |
|---|---|
| `17-transform-71-72-ebroker-apimain-esbv4-lookup.dql` | Live + verify |
| `16-transform-70-ebroker-address-conversion/` | #70 (confirmed) |
| `2026-10-14/16-cc-esbv4-ebroker-silent-dql/` | Earlier #70–#76 pack |
| `17.sh` | Dual-write |

## Commands

See [17.sh](17.sh).
