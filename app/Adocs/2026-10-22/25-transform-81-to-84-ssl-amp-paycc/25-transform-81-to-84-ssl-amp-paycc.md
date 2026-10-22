# Transform 81 To 84 SSL AMP PayCC

```
comment.sh 01–04 = migration #81–#84
#81 sslcert_lookup ebroker dest expires < 30d?
#82 portals-amp-backend error on …/save|ampUpdateCoverages|quote|bind?
#83 PayWithCreditCard_Adj + CAUGHT_EXCEPTION_ON_BACKEND (1d)?
#84 PayWithCreditCard_Adj + EXECUTION_COMPLETED (1d)?
```

| Key point | Detail |
|---|---|
| Labels | Your `01.`–`04.` are `#81`–`#84` |
| JSON parse | Nested `message` string → second `parse` (no wipe-all-`\`) |
| #82 URLs | Full gateway URLs → `endsWith("/save")` etc. |
| #83 / #84 | `contains(msg_url, "payWithCreditCard_Adj")` + exact `msg_type` |

## Summary

**81** is certificate lookup (or Synthetic). **82–84** are portals-amp-backend JSON logs with nested `message` parse.

Full live + verify DQL: companion `.dql` file.

## Data flow map

```
#81: sslcert_lookup → dest ebroker → ssl_end < now()+30d
#82–#84: portals-amp-backend → parse JSON → parse message
  → #82 endsWith URL + level=error
  → #83/#84 payWithCreditCard_Adj + type filter
```

## Related files

| File | Role |
|---|---|
| `25-transform-81-to-84-ssl-amp-paycc.dql` | Live + verify |
| `25.sh` | Dual-write |

## Commands

See [25.sh](25.sh).
