# Fix 83 To 85 PayCC Contains

```
Draft uses msg_url == "payWithCreditCard_Adj"?
 → No — full gateway URL → contains(..., caseSensitive:false)
Draft wipe-all-\ with replaceString?
 → No — parse JSON → parse message string (object path via coalesce)
#83 CAUGHT_EXCEPTION 1d | #84 EXECUTION_COMPLETED 1d | #85 same 1h
```

| Key point | Detail |
|---|---|
| Splunk | `message.url="*payWithCreditCard_Adj*"` |
| Wrong DQL | `msg_url == "payWithCreditCard_Adj"` |
| Right DQL | `contains(msg_url, "payWithCreditCard_Adj", caseSensitive:false)` |
| Parse | Nested string `message` → second `parse`; coalesce for object shape |

## Summary

Two fixes on your **#83–#85** drafts: **`contains`** for the URL, and **double-parse / coalesce** instead of wiping every `\`.

Full live DQL in companion `.dql`.

## Data flow map

```
content → JSON:j → message → url/type
  → contains payWithCreditCard_Adj
  → #83 CAUGHT_EXCEPTION (1d) | #84 COMPLETED (1d) | #85 COMPLETED (1h)
```

## Related files

| File | Role |
|---|---|
| `26-fix-83-to-85-paycc-contains.dql` | Live + verify |
| `25-transform-81-to-84-ssl-amp-paycc/` | Broader pack |
| `26.sh` | Dual-write |

## Commands

See [26.sh](26.sh).
