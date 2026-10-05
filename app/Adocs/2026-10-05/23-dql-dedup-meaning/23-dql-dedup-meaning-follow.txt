# DQL Dedup Meaning

## Decision tree

```
Do I need dedup in the LDAP alert?
 same ASA line arrives twice (two syslog paths)?  → YES → keep "dedup timestamp, content" (otherwise counts double)
 every line arrives once?                         → NO  → remove the dedup line (simpler, cheaper)
 how to tell?                                     → seq 21 check.dql: lines vs distinct_lines
   lines > distinct_lines → duplicates exist → keep dedup
   lines = distinct_lines → no duplicates     → drop dedup
```

## Short takeaway

| Question | Answer |
|---|---|
| What is `dedup`? | A DQL command that removes duplicate records. "Dedup" is short for de-duplicate |
| What does `dedup timestamp, content` do? | Keeps only one record for each unique pair of time and message text |
| Why is it in the LDAP alert? | Splunk had the same ASA message in two places. If Dynatrace also gets it twice, 2 real failures would count as 4 and cross the "more than 3" threshold |
| Splunk equivalent | `dedup _time _raw` |
| Do I always need it? | No. Only if duplicates really exist |

## Summary

`dedup` throws away repeated records so each real event is counted once. You tell it which fields make two records "the same". With `timestamp, content`, two log lines are treated as duplicates only when they have the exact same time and the exact same text, which is what happens when one firewall message is delivered through two syslog paths.

## How it works, step by step

Imagine the ASA sends 2 real failures, and each one reaches Dynatrace twice:

| timestamp | content | log.source |
|---|---|---|
| 10:00:01.120 | AAA Marking LDAP server 10.0.0.1 in aaa-server group Windows_LDAP as FAILED | syslog path A |
| 10:00:01.120 | AAA Marking LDAP server 10.0.0.1 in aaa-server group Windows_LDAP as FAILED | syslog path B |
| 10:00:30.450 | AAA Marking LDAP server 10.0.0.2 in aaa-server group Windows_LDAP as FAILED | syslog path A |
| 10:00:30.450 | AAA Marking LDAP server 10.0.0.2 in aaa-server group Windows_LDAP as FAILED | syslog path B |

Without dedup:

| Step | Result |
|---|---|
| `count()` for 10:00 | 4 |
| Threshold "more than 3" | Breached, so the alert fires on only 2 real failures |

With `dedup timestamp, content`:

| timestamp | content |
|---|---|
| 10:00:01.120 | ...10.0.0.1... as FAILED |
| 10:00:30.450 | ...10.0.0.2... as FAILED |

| Step | Result |
|---|---|
| `count()` for 10:00 | 2 |
| Threshold "more than 3" | Not breached, which is correct |

## Choosing the fields

| You write | Two records count as the same when | Use it when |
|---|---|---|
| `dedup timestamp, content` | Same time and same text | The same line can arrive twice (our case) |
| `dedup content` | Same text, any time | You want each distinct message once, for example in a report |
| `dedup host.name` | Same host | You want one row per host, for example "last line per server" |
| `dedup host.name, sort:{timestamp desc}` | Same host, keeps the newest | "Latest record per host" |

The fields you pick matter. `dedup content` alone would be wrong for the alert, because two real failures with the same text a few seconds apart would collapse into one.

## Small risk to know about

If the ASA genuinely logs the same message twice in the same millisecond, dedup collapses them into one. That's rare, and for a "more than 3 per minute" alert it makes almost no difference.

## Checking whether you need it

Run this (seq 21 `check.dql` query 2):

```dql
fetch logs, from:now()-30d
| filter matchesValue(dt.system.bucket, "network*")
| filter contains(content, "Windows_LDAP as FAILED", caseSensitive: false)
| summarize lines = count(), distinct_lines = countDistinct(concat(toString(timestamp), content))
```

| Result | What to do |
|---|---|
| `lines` bigger than `distinct_lines` | Duplicates exist. Keep `dedup timestamp, content` |
| `lines` equals `distinct_lines` | No duplicates. Remove the dedup line |

If Dynatrace rejects the `dedup` line, test it alone in a Notebook first (`fetch logs | dedup timestamp, content | limit 10`) and remove it from the alert if it doesn't run.

## Data flow

```
ASA message
  → syslog path A ─┐
  → syslog path B ─┴→ Grail: 2 identical records
  → dedup timestamp, content → 1 record
  → makeTimeseries count → correct per-minute count
  → threshold 3
```

## Investigation

| Checked | Finding |
|---|---|
| Your question | What `dedup` means in the seq 21 query |
| Seq 21 | Two Splunk alerts read the same ASA message from two index and sourcetype pairs |
| Risk without dedup | Double counting makes the alert fire on half the real failures |

## Result

`dedup` removes duplicate records. In the LDAP alert it keeps one record per unique time and text, so a message delivered twice is counted once. Keep it only if the check query shows duplicates.

## Related files

| File | Purpose |
|---|---|
| `2026-10-05/21-cisco-vpn-ldap-two-alerts-transform/21-cisco-vpn-ldap-two-alerts-transform-check.dql` | Duplicate check |
| `2026-10-05/22-terraform-variables-inside-resource/` | Inline version of the alert with the dedup line |
| `23.sh` | Mirror and git one-liners |

## Commands

See `23.sh` (not run).
