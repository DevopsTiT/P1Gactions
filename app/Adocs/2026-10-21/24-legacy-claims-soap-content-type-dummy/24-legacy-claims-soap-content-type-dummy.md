# Legacy Claims SOAP Content Type Dummy

```
Want filter dummy like afterBind?
 → fetch logs
 → fieldsAdd dummy = "<piece of the Splunk line>"
 → fields dummy
 → filter contains(dummy, …)
 → Pass = dummy row still shows
 → Then run live fetch on pc2-ui + same phrases
```

| Key point | Detail |
|---|---|
| What the log says | SOAP call to LegacyDataClaims got `text/plain` instead of XML |
| Service | `LegacyDataClaimsService` / `fetchClaimDetails` |
| Host pattern (Splunk) | `pc2-ui-ins-prod-*`, sourcetype `pc2-ui` |

## Summary

Use a short piece of your real event as `dummy`, then apply the same `contains` filters. That proves the phrase logic before you trust a live query.

## Example log piece (from your screen)

```
XML.Runtime - Operation failed for service LegacyDataClaimsService, PortType: LegacyDataClaimsPort, Operation: fetchClaimDetails - SOAP response envelope from [https://esbv4-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa/esb/legacyclaims/services/LegacyData/Claims] had wrong content type, "text/plain". Expected one of [text/xml, application/soap+xml, application/xml].
```

---

## Verify — filter dummy (like afterBind)

```
// Verify:
fetch logs
| fieldsAdd dummy = "XML.Runtime - Operation failed for service LegacyDataClaimsService, PortType: LegacyDataClaimsPort, Operation: fetchClaimDetails - SOAP response envelope from [https://esbv4-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa/esb/legacyclaims/services/LegacyData/Claims] had wrong content type, \"text/plain\". Expected one of [text/xml, application/soap+xml, application/xml]."
| fields dummy
| filter contains(dummy, "LegacyDataClaimsService", caseSensitive:false)
    and contains(dummy, "wrong content type", caseSensitive:false)
    and contains(dummy, "text/plain", caseSensitive:false)
```

**Pass:** you still see the dummy line.

### Minimal (two phrases only)

```
fetch logs
| fieldsAdd dummy = "XML.Runtime - Operation failed for service LegacyDataClaimsService - had wrong content type, \"text/plain\". Expected one of [text/xml, application/soap+xml, application/xml]."
| fields dummy
| filter contains(dummy, "LegacyDataClaimsService", caseSensitive:false)
    and contains(dummy, "wrong content type", caseSensitive:false)
```

---

## Live filter (real logs)

```
fetch logs, from:now()-24h
| filter startsWith(host.name, "pc2-ui")
    or startsWith(k8s.pod.name, "pc2-ui")
    or contains(log.source, "pc2-ui", caseSensitive:false)
| filter contains(content, "LegacyDataClaimsService", caseSensitive:false)
    and contains(content, "wrong content type", caseSensitive:false)
    and contains(content, "text/plain", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, content
```

Optional tighter (same as your message):

```
| filter contains(content, "fetchClaimDetails", caseSensitive:false)
    and contains(content, "XML.Runtime", caseSensitive:false)
```

---

## Side by side with afterBind style

| afterBind | This one |
|---|---|
| `Exception occured for job` + `during afterBind_Adj process` | `LegacyDataClaimsService` + `wrong content type` (+ `text/plain`) |
| `fieldsAdd dummy = "…"` | same |
| `filter contains(dummy, …)` | same |

## Data flow map

```
Splunk event text
  → fieldsAdd dummy = that text
  → filter phrases on dummy
  → pass → use same phrases on content (live)
```

## Related files

| File | Role |
|---|---|
| `24-legacy-claims-soap-content-type-dummy.dql` | Copy-paste |
| `24.sh` | Mirror |

## Commands

See [24.sh](./24.sh).
