# BC2 GMO And Producer Errors DQL

## Decision tree

```
Which SPL?
 #45 to #49, #53 → repeats → reuse answer 14
 #50 → parse errcode → keep E01 → drop 3 known errinfo codes
 #51 → two phrases, brackets are literal
 #52, #55 → single phrase
 #54 → "Operation failed" + Producer phrase (Japanese part unreadable)
 0 rows? → answer 14 check query → still 0? → onboarding request
```

## Short takeaway

| SPL | What it finds |
|---|---|
| #45 to #49 | Same as answer 14 #39 to #43 |
| #50 | bc2-ui GMO errors with errcode E01, except three known errinfo codes |
| #51 | bc2-batch saveCardWithOrderID errors on writer thread 54 |
| #52 | GMO SearchTrade used to confirm ExecTran status |
| #53 | Same as answer 14 #43 |
| #54 | pc2-ui or bc2-ui "Operation failed" about a Producer |
| #55 | bc2 "Producer Contact is missing for Producer" |

## Summary

Only #50 to #52, #54, and #55 are new. #50 is the only one that needs a field: Splunk reads `errcode=E01` as a field, so DQL parses `errcode` first and compares it exactly.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `errcode=E01` (Splunk) | A field match, not a text match. `errcode` must equal `E01`. |
| `ALNUM` | DQL parse matcher for letters and digits. |
| `\[54\]` (Splunk) | Escaped brackets. The real text is `[54]`. |
| `NOT term` | Exclude lines containing that term. |

### Mapping

| Splunk piece | DQL piece | Why |
|---|---|---|
| `errcode=E01` | `parse content, "LD 'errcode=' ALNUM:errcode"` then `errcode == "E01"` | Exact field value, not a substring. |
| `AND NOT E01130002` | `not contains(content, "E01130002")` | Exclude known codes. |
| `"MW-Writer-\[54\]"` | `contains(content, "MW-Writer-[54]")` | DQL `contains()` needs no escaping. |
| `index=pc2-ui* OR index=bc2-ui* "Operation failed" AND (...)` | (pc2-ui or bc2-ui) and phrase and (...) | Splunk OR binds before AND. |

### Things to verify

| Item | Why |
|---|---|
| #54 Japanese text | Unreadable. The filter uses the English part only, so it may return extra rows. |
| App prefixes | Confirm with the answer 14 check query. |

## Result

All queries are in `15-bc2-gmo-producer-errors-dql.dql`. The chat reply has every query in full.

## Data flow map

```
#50  bc2-ui logs -> "Map returned by method call" -> errcode == E01 -> drop 3 codes -> list
#51  bc2-batch logs -> saveCardWithOrderID error -> MW-Writer-[54] -> list
#52  bc2 apps -> SearchTrade confirm phrase -> list
#54  pc2-ui / bc2-ui -> "Operation failed" -> Producer phrase -> list
#55  bc2 apps -> Producer Contact missing -> list
```

## Related files

| File | What it holds |
|---|---|
| `15-bc2-gmo-producer-errors-dql.dql` | All new queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Notes |
| `2-result.md` | Result summary |
| `3-glossary.md` | Glossary |
| `15.sh` | Git one-liners |

## Commands

See `15.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/15-bc2-gmo-producer-errors-dql
git commit -m "BC2 GMO and producer errors DQL"
git push
```
