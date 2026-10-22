# Transform 70 Ebroker Address Conversion

```
#70 cut off at index=ebroker?
 → use known SPL: ebroker* + Address conversion failed (Zipcode OR Status code)
 → startsWith(src, "ebroker") + two contains() with or
 → verify with dummy (no space after failed.)
```

| Key point | Detail |
|---|---|
| Question | What is #70 when the screenshot only shows `index=ebroker`? |
| Answer | Ebroker address conversion failures against agrex (zipcode request fail or bad status code) |
| Phrases | No space after `failed.` — exact text matters |
| Source | Same as `2026-10-14/16-cc-esbv4-ebroker-silent-dql` and `15-splunk-1-to-85` part-3 |

## Summary

**#70** watches ebroker for two address-conversion failure strings. Splunk uses `OR` on the phrases; DQL uses two `contains(..., caseSensitive:false)` joined with `or`.

---

## Splunk (rebuilt)

```
index="ebroker*"
("Address conversion failed.Request to agrex Zipcode:" OR "Address conversion failed.Status code")
```

## #70 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "ebroker")
    or contains(log.source, "ebroker", caseSensitive:false)
| filter contains(content, "Address conversion failed.Request to agrex Zipcode:", caseSensitive:false)
    or contains(content, "Address conversion failed.Status code", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #70 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 WARN [http-nio-8080-exec-3] c.e.ebroker.address.AddressService - Address conversion failed.Request to agrex Zipcode: 1000001"
| fieldsAdd pod = "ebroker-api-5b7c9d8f6-q8w2r"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "ebroker")
| filter contains(dummy, "Address conversion failed.Request to agrex Zipcode:", caseSensitive:false)
    or contains(dummy, "Address conversion failed.Status code", caseSensitive:false)
| fields src, dummy
```

Near miss (should not match): a space after `failed.` — for example `failed. Request` — breaks both phrases.

## Data flow map

```
ebroker* logs
  → src starts with ebroker (or log.source has ebroker)
  → Address conversion failed.Request to agrex Zipcode:
       OR Address conversion failed.Status code
  → timestamp, src, content
```

## Related files

| File | Role |
|---|---|
| `16-transform-70-ebroker-address-conversion.dql` | Live + verify |
| `15-transform-66-to-69-cc-sonpov-esbv4/` | Prior pack (#66–#69) |
| `2026-10-14/16-cc-esbv4-ebroker-silent-dql/` | Original #70 pack |
| `16.sh` | Dual-write |

## Commands

See [16.sh](16.sh).
