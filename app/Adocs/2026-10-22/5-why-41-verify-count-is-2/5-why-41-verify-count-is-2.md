# Why 41 Verify Count Is 2

```
Verify shows count = 2?
 → fetch logs | limit 2  → two rows
 → fieldsAdd content = same dummy on both rows
 → summarize groups them → count() = 2
 → that is fake duplicate for testing, not live data
```

| Key point | Detail |
|---|---|
| What count means | How many **rows** share the same Identifier + Amount + PaymentDate |
| Why it is 2 here | You forced **two** rows to use the **same** dummy line |
| Live meaning | In production, count &gt; 1 means a real duplicate group |

## Summary

Your Notebook did not find two real CVS payments. `limit 2` plus one shared `fieldsAdd content` creates two identical rows on purpose so `filter count > 1` can return a row and prove the pipeline works.

## Step by step

| Step | What happens | Row count |
|---|---|---|
| `fetch logs` | Pulls real logs (any) | many |
| `limit 2` | Keep only two of those rows | 2 |
| `fieldsAdd content = "...CVS-000731..."` | Overwrite both rows with the **same** text | still 2, same values |
| `parse` Identifier / Amount / PaymentDate | Both rows → `CVS-000731` / `12000` / same date | 2 |
| `summarize count(), by:{...}` | One group, counted twice | **count = 2** |
| `filter count > 1` | Keep that group | 1 result row |

## Picture

```
row A ──┐
        ├── same Identifier, Amount, PaymentDate  →  count = 2
row B ──┘
```

## If you want count = 1 in verify

Use one row only (then drop `filter count > 1`, or expect 0 rows after that filter):

```
fetch logs
| limit 1
| fieldsAdd content = "2026-10-14 02:10:05,120 INFO [CvsImport-1] PaymentRecordType=Quick record for CVS Offline, Identifier=CVS-000731, Amount=12000, PaymentDate=Wed Oct 14 10:00:00 JST 2026, RunID=R-0101"
| fields content
| parse content, "LD 'Identifier=' LD:Identifier ','"
| parse content, "LD 'Amount=' LD:Amount ','"
| parse content, "LD 'PaymentDate=' LD:PaymentDate ','"
| summarize count = count(), by:{ Identifier, Amount, PaymentDate }
| fields Identifier, Amount, PaymentDate, count
```

**Result:** `count = 1` (and `filter count > 1` would remove it).

## Live vs verify

| Query | What count &gt; 1 means |
|---|---|
| Verify (`limit 2` + same dummy) | Test harness — expected |
| Live #41 | Real duplicate payment keys in bc2-batch logs |

## Data flow map

```
limit 2
  → same dummy content on both rows
  → summarize by Identifier, Amount, PaymentDate
  → count = 2
```

## Related files

| File | Role |
|---|---|
| `4-transform-41-bc2-cvs-offline-duplicates/` | Full #41 live + verify |
| `5.sh` | Dual-write |

## Commands

See [5.sh](5.sh).
