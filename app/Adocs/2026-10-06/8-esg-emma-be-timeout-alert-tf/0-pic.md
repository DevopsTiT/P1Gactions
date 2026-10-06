# ESG Emma BE Timeout Picture

```
backend SocketTimeoutException  ─┐
API gateway "Problem routing ... timed out" ─┴→ count in last 5 min
  > 20 → High problem → email (no page)
  ≤ 20 → nothing
```
