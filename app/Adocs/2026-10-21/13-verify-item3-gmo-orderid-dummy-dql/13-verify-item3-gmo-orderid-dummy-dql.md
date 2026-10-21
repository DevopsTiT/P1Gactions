# Verify Item 3 GMO Orderid Dummy DQL

```
Want to test #3 without real bc2 logs?
 → Verify A: one dummy line → see orderid / Time / OrderIDPattern parse
 → Verify B: two lines same pattern, different Time → count > 1 row appears
 → Parse wrong? → check &orderid= … &forward= cut points
 → Then run the real fetch logs query from seq 3 / your editor
```

| Key point | Detail |
|---|---|
| What #3 does | Find GMO “Map returned by method call” lines whose orderids match except a 6-char time middle |
| Why dummy verify | Prove substring / pattern / count logic before relying on live logs |
| Style | Same idea as your afterBind_Adj `fieldsAdd dummy = "…"` verify |

## Summary

Paste **Verify A** first (one row, shows the cut). Then paste **Verify B** (two orderids that should collapse to one `OrderIDPattern` with `count = 2`). No Slack webhook and no live bc2 data required.

## Dummy orderids used (made up)

| Full orderid | OrderID_noTime (18) | Time (6) | Rest | OrderIDPattern |
|---|---|---|---|---|
| `ABC123456789012345093015001` | `ABC123456789012345` | `093015` | `001` | `ABC123456789012345*001` |
| `ABC123456789012345101200001` | `ABC123456789012345` | `101200` | `001` | `ABC123456789012345*001` (same) |
| `ZZZ999999999999999120000999` | different | | | different — should not join the duplicate row |

---

## Verify A — parse one dummy line (like your afterBind verify)

Same style as:

```
fetch logs
| fieldsAdd dummy = "Exception occured for job …"
| fields dummy
| filter contains(dummy, …)
```

For #3:

```
// Verify #3A — cut orderid + build OrderIDPattern from one fake line
fetch logs
| fieldsAdd content = "2026-10-19 15:35:12,398 INFO [http-nio-8080-exec-4] Integration.GMO - Map returned by method call [acs=0&paytimes=&tranid=2610191535602257224925901183&checkstring=&clientfield3=&clientfield2=&method=1&clientfield1=&orderid=ABC123456789012345093015001&forward=X&approve=&trandate=20261019]"
| fields content
| filter contains(content, "Integration.GMO")
    and contains(content, "Map returned by method call", caseSensitive:false)
    and contains(content, "[acs=0&paytimes=&tranid=")
    and contains(content, "&clientfield3=&clientfield2=&method=1&clientfield1=")
    and contains(content, "&orderid=")
    and contains(content, "&trandate=")
| fieldsAdd after_orderid = substring(content, from: indexOf(content, "&orderid=") + 9)
| fieldsAdd orderid = substring(after_orderid, from:0, to: indexOf(after_orderid, "&"))
| fieldsAdd OrderID_noTime = substring(orderid, from:0, to:18),
            Time = substring(orderid, from:18, to:24),
            Rest = substring(orderid, from:24)
| fieldsAdd OrderIDPattern = concat(OrderID_noTime, "*", Rest)
| fields content, orderid, OrderID_noTime, Time, Rest, OrderIDPattern
```

**Pass when you see:**

| Field | Expected |
|---|---|
| orderid | `ABC123456789012345093015001` |
| OrderID_noTime | `ABC123456789012345` |
| Time | `093015` |
| Rest | `001` |
| OrderIDPattern | `ABC123456789012345*001` |

---

## Verify B — duplicate pattern (full #3 logic, no live logs)

Uses `data record` so you invent two matching lines + one unique line.

```
// Verify #3B — two orderids same pattern (different Time) → count > 1
data record(
    content: "INFO Integration.GMO Map returned by method call [acs=0&paytimes=&tranid=T1&checkstring=&clientfield3=&clientfield2=&method=1&clientfield1=&orderid=ABC123456789012345093015001&forward=X&approve=&trandate=20261019]"
  ),
  record(
    content: "INFO Integration.GMO Map returned by method call [acs=0&paytimes=&tranid=T2&checkstring=&clientfield3=&clientfield2=&method=1&clientfield1=&orderid=ABC123456789012345101200001&forward=X&approve=&trandate=20261019]"
  ),
  record(
    content: "INFO Integration.GMO Map returned by method call [acs=0&paytimes=&tranid=T3&checkstring=&clientfield3=&clientfield2=&method=1&clientfield1=&orderid=ZZZ999999999999999120000999&forward=X&approve=&trandate=20261019]"
  )
| filter contains(content, "Integration.GMO")
    and contains(content, "Map returned by method call", caseSensitive:false)
    and contains(content, "[acs=0&paytimes=&tranid=")
    and contains(content, "&clientfield3=&clientfield2=&method=1&clientfield1=")
    and contains(content, "&orderid=")
    and contains(content, "&trandate=")
| fieldsAdd after_orderid = substring(content, from: indexOf(content, "&orderid=") + 9)
| fieldsAdd orderid = substring(after_orderid, from:0, to: indexOf(after_orderid, "&"))
| dedup orderid
| filter stringLength(orderid) >= 24
| fieldsAdd OrderID_noTime = substring(orderid, from:0, to:18),
            Time = substring(orderid, from:18, to:24),
            Rest = substring(orderid, from:24)
| fieldsAdd OrderIDPattern = concat(OrderID_noTime, "*", Rest)
| summarize count = count(), orderids = collectDistinct(orderid), by:{ OrderIDPattern }
| filter count > 1
| sort count desc
```

**Pass when you see one row:**

| OrderIDPattern | count | orderids (idea) |
|---|---|---|
| `ABC123456789012345*001` | 2 | the two `ABC…` ids |

The `ZZZ…` line must **not** appear (its count is 1).

---

## If your Notebook rejects `data record`

Use the same `fetch logs` + `fieldsAdd content = "…"` trick twice is awkward for multi-row. Prefer `data record`. If `data` is unavailable, run **Verify A** only, then trust the live query for count > 1.

---

## After dummy passes — real query (unchanged)

```
fetch logs, from:now()-24h
| filter startsWith(host.name, "bc2-") or startsWith(k8s.pod.name, "bc2-")
| filter contains(content, "Integration.GMO")
    and contains(content, "Map returned by method call", caseSensitive:false)
    and contains(content, "[acs=0&paytimes=&tranid=")
    and contains(content, "&clientfield3=&clientfield2=&method=1&clientfield1=")
    and contains(content, "&orderid=")
    and contains(content, "&trandate=")
| fieldsAdd after_orderid = substring(content, from: indexOf(content, "&orderid=") + 9)
| fieldsAdd orderid = substring(after_orderid, from:0, to: indexOf(after_orderid, "&"))
| dedup orderid
| filter stringLength(orderid) >= 24
| fieldsAdd OrderID_noTime = substring(orderid, from:0, to:18),
            Time = substring(orderid, from:18, to:24),
            Rest = substring(orderid, from:24)
| fieldsAdd OrderIDPattern = concat(OrderID_noTime, "*", Rest)
| summarize count = count(), orderids = collectDistinct(orderid), by:{ OrderIDPattern }
| filter count > 1
| sort count desc
```

## Data flow map

```
Dummy content (fake GMO map line)
  → filter markers (Integration.GMO, Map returned…, orderid=, …)
  → cut orderid between &orderid= and next &
  → split 18 + 6 + rest → OrderIDPattern
  → (Verify B) group → keep patterns with count > 1
```

## Related files

| File | Role |
|---|---|
| `13-verify-item3-gmo-orderid-dummy.dql` | Copy-paste queries only |
| `../2026-10-14/3-bc2-gmo-duplicate-orderid-dql/` | Original #3 main DQL |
| `13.sh` | Copy to Adocs / Files |

## Commands

See [13.sh](./13.sh).
