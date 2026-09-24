# Splunk Alerts To Dynatrace Dql

```
Transfer rule
  Splunk index     → filter aws.log_group OR log.source contains <index>
  Splunk message   → filter content
  Splunk logGroup  → filter aws.log_group
  Splunk dedup     → summarize … by: { … }
  Splunk rex       → parse (or contains fallback)

Always
  → same time range as Splunk
  → discover scope if counts differ (see seq 4)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Source | `1 copy.sh` screenshots (Migration / Retry1) |
| Output | `5-all-splunk-alerts-to-dql.dql` — one DQL block per alert |
| Scope tip | Index ≠ one Lambda; widen if counts are low |
| Truncated | Some Splunk lines cut off in photos — marked TODO in `.dql` |

## Summary

All visible Splunk alerts from the file were translated to Dynatrace Grail DQL. Use one query at a time in Logs/Notebooks. Confirm TODO phrases against the full `1 copy.sh` on disk when you have it.

## Investigation

User sent ~10 screenshots of Splunk alerts (sections 1–16). File not found on this Mac under Learnings/Work/Codes. Transfers built from screenshot text; truncated tails noted.

## Result

Open `5-all-splunk-alerts-to-dql.dql`. Map table below lists every alert. Fix TODOs after you paste the complete Splunk lines.

---

## Mapping cheat sheet

| Splunk | Dynatrace DQL |
| --- | --- |
| `index=foo` | `filter contains(aws.log_group,"foo") or contains(log.source,"foo")` |
| `message="*bar*"` | `filter contains(content,"bar", caseSensitive:false)` |
| `message!="*x*"` | `filter not contains(content,"x")` |
| `logGroup="/aws/..."` | `filter contains(aws.log_group,"/aws/...")` |
| `spath logGroup` | Use `aws.log_group` (already a field when ingested from CW) |
| `"error"` free-text | `contains(content,"error")` |
| `dedup message` | `summarize … by: { content }` |
| `rex` / `table` | `parse` + `fields` (or keep `content` for alerts) |
| `where N > 400` | `parse` number then `filter MemoryUsage > 400` |

---

## Alert → DQL index (by section)

| # | Service | Alert | DQL notes |
| --- | --- | --- | --- |
| 1 | cci-fa-comm-calc | CCI_AWS_Batch Time Out | Task timed out, exclude !DEBUG! |
| 2 | cmx-sharepoint-api | CMXtoSharepoint Error | content Error |
| 3 | compass-sales | Glue Skip | glue error log group + skipping table |
| 4a | cs-digital-document-management | Error alerts | error, exclude elivery not possible |
| 4b | same | Claims API fails | prod-* lambda + claims api call failed |
| 5a | customer-process-api | API Alerts | OR of error phrases (TODO Got unex*) |
| 5b | same | Success 201 | statusCode 201 |
| 6a–e | document-upload-api | Batch/CMX/DB/Failed/Pending | log group + phrases; TODOs on tails |
| 7a–b | eopt-serverless | ERROR level | contains ERROR |
| 8a–h | gov-inquiry-system | file summaries + errors | log group + Biz file summary / level:ERROR |
| 9 | hpm-sharepoint-api | Lambda Error | ERROR |
| 10 | hpm-survey-monkey | Lambda Error | ERROR |
| 11 | innorules | BRE alert | ERROR |
| 12 | message-box-api | MsgBox errors | error OR warn |
| 13a–e | myaxa-onboarding-batch | five Emma High alerts | exact phrase each |
| 14 | pmt-api | many | phrases + memory >400/>480 + unexpected exclude sfdc |
| 15 | recruitimp-serverless | RI / AWS Error | ERROR / level:ERROR |
| 16 | sa-support-batches | three | error / import* / Task timed out |

---

## How to use

| Step | Action |
| --- | --- |
| 1 | Open Dynatrace → Logs or Notebooks |
| 2 | Set time range = Splunk alert window |
| 3 | Paste **one** query from the `.dql` file (skip `//` comment blocks) |
| 4 | If few rows: run discover for that index name (seq 4 pattern) |
| 5 | For TODO alerts: paste full Splunk line from `1 copy.sh` and tighten the string |

---

## Data flow map

```
1 copy.sh (Splunk alerts)
  → map index/logGroup/message
  → DQL fetch logs | filter | fields
  → validate counts vs Splunk
  → then wire to Davis / Workflow / alert later
```

---

## Related files

| File | Role |
| --- | --- |
| `5-all-splunk-alerts-to-dql.dql` | All transferable DQL |
| `4-splunk-to-dql-scope-transfer/` | Why scope differs |
| `5.sh` | Optional open helpers |

## Commands

See `5.sh`.
