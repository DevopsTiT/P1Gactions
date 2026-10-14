# BC2 GMO Duplicate OrderID DQL

## Decision tree

```
Splunk: GMO "Map returned by method call" lines → orderid → cut out 6 char time → count same pattern → more than 1
 index=bc2*                       → host.name or k8s.pod.name starts with "bc2-"
 Integration.GMO AND "..." AND "[acs=0&...&trandate=*]"
                                  → contains() for each fixed piece (Splunk * becomes "skip")
 orderid (Splunk auto field)      → substring between "&orderid=" and the next "&"
 dedup orderid                    → dedup orderid
 rex .{18} .{6} .*                → substring 0-18, 18-24, 24-end
 eval OrderID_noTime."*".Rest     → concat(OrderID_noTime, "*", Rest)
 stats count by OrderIDPattern    → summarize count = count(), by:{ OrderIDPattern }
 where count > 1, sort - count    → filter count > 1, sort count desc
 empty? → check 1 (bc2 logs in Dynatrace?) → check 2 (orderid cut correct?)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it find? | GMO payment orders that were sent more than once, ignoring the 6-character time part of the order ID. |
| Hosts | bc2-ui-inssuite-prod-0 and -1, bc2-batch-inssuite-prod-0 and -1. |
| How is orderid found? | Text between `&orderid=` and the next `&` in the log line. |
| Output | One row per order pattern with count above 1, plus the actual order IDs. |
| Risk | bc2 logs come to Splunk from S3 `axa-gi-jp-logforwarders-prod`. They may not be in Dynatrace yet. |

## Summary

Each GMO call logs a parameter string with an `orderid`. The order ID has an 18-character prefix, a 6-character time, and a tail. Removing the time and grouping shows when the same order was sent at different times, which points to duplicate payments. The DQL does the same steps in the same order.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| GMO | GMO Payment Gateway, a Japanese card payment service. | These lines are payment calls. |
| `orderid` | The order number sent to GMO. | Duplicates may mean double charging. |
| `dedup` | Keep only the first row for each value. | Same order ID logged twice counts once. |
| `rex` | Splunk regex that cuts text into named parts. | DQL uses `substring` here because the parts have fixed lengths. |
| `.{18}` | Exactly 18 characters. | The first part of the order ID. |
| `substring(x, from:a, to:b)` | Characters from position a up to (not including) b, counting from 0. | Replaces the fixed length regex. |
| `indexOf` | Position of a piece of text inside a string. | Finds where `&orderid=` starts. |

### What the screenshots show

| Item | Value |
|---|---|
| Base search | index=bc2* |
| Events | 849,714 |
| Host 1 | bc2-ui-inssuite-prod-0 (373,569, 45.3%) |
| Host 2 | bc2-ui-inssuite-prod-1 (370,976, 45.0%) |
| Host 3 | bc2-batch-inssuite-prod-0 (47,247, 5.7%) |
| Host 4 | bc2-batch-inssuite-prod-1 (32,895, 4.0%) |
| Source | s3://axa-gi-jp-logforwarders-prod/2026/10/14/... |
| Line format | `2026-10-14 09:26:39,285 INFO [https-jsse-nio-8443-exec-74] com.axa.adj.gw...` |

### Splunk to DQL

| Splunk | DQL | Note |
|---|---|---|
| `index=bc2*` | `startsWith(host.name, "bc2-") or startsWith(k8s.pod.name, "bc2-")` | Covers all four hosts. |
| `Integration.GMO` | `contains(content, "Integration.GMO")` | Logger or class name in the line. |
| `"Map returned by method call"` | `contains(content, "Map returned by method call", caseSensitive:false)` | |
| `"[acs=0&paytimes=&tranid=*&checkstring=*&clientfield3=&clientfield2=&method=1&clientfield1=*&orderid=*&forward=*&approve=*&trandate=*]"` | Four `contains()` on the fixed pieces | Splunk `*` means "anything". DQL checks the parts between the stars. |
| Auto field `orderid` | `substring` between `&orderid=` and the next `&` | Splunk pulled it from `key=value` text automatically. |
| `dedup orderid` | `dedup orderid` | Same command name. |
| `rex field=orderid "(?<OrderID_noTime>.{18})(?<Time>.{6})(?<Rest>.*)"` | `substring(orderid, from:0, to:18)`, `from:18, to:24`, `from:24` | `stringLength(orderid) >= 24` keeps only IDs the regex would match. |
| `eval OrderIDPattern=OrderID_noTime."*".Rest` | `concat(OrderID_noTime, "*", Rest)` | Splunk `.` joins text. |
| `stats count by OrderIDPattern` | `summarize count = count(), by:{ OrderIDPattern }` | `orderids` added so you can see the real IDs. |
| `where count > 1` | `filter count > 1` | |
| `sort - count` | `sort count desc` | |

### Pieces of the parameter string

| Splunk piece | DQL check |
|---|---|
| `[acs=0&paytimes=&tranid=` then anything | `contains(content, "[acs=0&paytimes=&tranid=")` |
| `&checkstring=` then anything | Covered by the next check. |
| `&clientfield3=&clientfield2=&method=1&clientfield1=` then anything | `contains(content, "&clientfield3=&clientfield2=&method=1&clientfield1=")` |
| `&orderid=` then anything | `contains(content, "&orderid=")` |
| `&forward=`, `&approve=` then anything | Not checked. They sit between orderid and trandate. Add if you want it stricter. |
| `&trandate=` then anything | `contains(content, "&trandate=")` |

## Result

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

### How one order ID is cut

Example (made up): `ABC123456789012345093015001`

| Part | Positions | Value |
|---|---|---|
| OrderID_noTime | 0 to 18 | `ABC123456789012345` |
| Time | 18 to 24 | `093015` |
| Rest | 24 to end | `001` |
| OrderIDPattern | | `ABC123456789012345*001` |

If a second line has `ABC123456789012345101200001`, it gets the same pattern. Count becomes 2 and the row shows.

### If it returns 0

| Check | Result | Meaning |
|---|---|---|
| Check 1 (bc2 in any field) | 0 | bc2 logs are not in Dynatrace. Same gap as eopt. Ask for forwarding. |
| Check 1 | Rows | Logs exist. Use the field that holds the pod name. |
| Check 2 (orderid cut) | Empty or odd `orderid` | The line format differs. Paste one raw line and adjust the `indexOf` text. |
| Main query | 0 but checks look fine | No duplicates in the time range. That is the good outcome. |

## Data flow map

```
bc2-ui / bc2-batch pods (GMO payment calls)
  → S3 axa-gi-jp-logforwarders-prod → Splunk ✔
  → Dynatrace Grail ? (check 1)
        → fetch logs, last 24 h
        → keep bc2 pods and GMO "Map returned by method call" lines
        → cut orderid out of the parameter string
        → one row per orderid
        → remove the 6-char time → pattern
        → count per pattern → keep count > 1 → biggest first
```

## Related files

| File | What it holds |
|---|---|
| `3-bc2-gmo-duplicate-orderid-dql.dql` | Main query and two checks. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Screenshot facts. |
| `2-result.md` | Final query and empty-result guide. |
| `3-glossary.md` | Words used. |
| `3.sh` | Git one-liners. |

## Commands

Run the queries in a Dynatrace Notebook. Git one-liners are in [`3.sh`](./3.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/3-bc2-gmo-duplicate-orderid-dql
git commit -m "BC2 GMO duplicate orderid DQL"
git push
```
