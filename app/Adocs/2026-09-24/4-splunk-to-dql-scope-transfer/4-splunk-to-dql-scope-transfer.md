# Splunk To Dynatrace Scope Transfer

```
Splunk many rows, Dynatrace few?
  → Usually SCOPE mismatch (not only the "error" text filter)

Splunk index="cs-digital-document-management"
  ≠  one Lambda log group "...-prod"

Fix order:
  1) Discover what Dynatrace actually stored for that app
  2) Widen or remap scope to match the index
  3) Then apply the same error / exclude logic
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Is scope different? | **Yes** — that is the main reason for “many vs few” |
| Splunk scope | Whole **index** `cs-digital-document-management` (all sources in that index) |
| Your DQL scope | Only log group containing `/aws/lambda/cs-digital-document-management-prod` |
| Right transfer | Map index → the Dynatrace fields that cover the **same logs**, then filter `content` like `message` |
| First step | Run a **discover** query before locking `-prod` |

## Summary

The Splunk query searches an entire index (and a free-text `"error"` hit), then filters the `message` field. Your Dynatrace query only keeps one **prod Lambda** log group, then filters `content`. That is a narrower bucket, so fewer rows are expected until you align scope. The word filters (`error` / exclude `elivery not possible`) are a fair translation once scope matches.

## Investigation

Teams standup screenshot: Splunk index query vs DQL with `aws.log_group` `...-prod`. Compared index vs log-group, field `message` vs `content`, and free-text `"error"` vs `contains(content,"error")`.

## Result

Use the discover → widen → filter pattern below. Do not treat “one Lambda prod log group” as equal to the Splunk index unless you have proven that index only holds that one group.

---

## 1) Plain English: what each query asks

### Splunk (original)

```spl
index="cs-digital-document-management" "error"
| search message="*error*" AND message!="*elivery not possible*"
```

| Piece | What it means |
| --- | --- |
| `index="cs-digital-document-management"` | Search **everything** stored in that Splunk index |
| `"error"` (before the pipe) | Free-text: event must contain the word error somewhere |
| `message="*error*"` | Field `message` contains `error` |
| `message!="*elivery not possible*"` | Exclude noisy “Delivery not possible” style lines (typo kept as in Splunk) |

### Your Dynatrace attempt

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/cs-digital-document-management-prod")
| filter contains(content, "error", caseSensitive: false)
| filter not contains(content, "elivery not possible", caseSensitive: false)
```

| Piece | What it means |
| --- | --- |
| `fetch logs` | Read Dynatrace Grail logs |
| `aws.log_group` … `-prod` | **Only** that prod Lambda CloudWatch log group |
| `contains(content, "error")` | Rough match for Splunk `message` / keyword error |
| `not contains(… elivery…)` | Same exclude idea |

---

## 2) Why “scope is different” (yes)

| Dimension | Splunk | Your DQL | Effect |
| --- | --- | --- | --- |
| Bucket | Whole **index** | One **log group** string with `-prod` | DQL much narrower |
| Environments | Index name has **no** `-prod` | Explicit **prod** only | Drops non-prod if they were in Splunk index |
| Sources | Index can hold many sources (several Lambdas, other AWS logs, app logs) | One path under `/aws/lambda/…` | Misses sibling log groups |
| Text field | `message` (+ free-text on event) | `content` only | Can miss if text lives in other attributes |
| Time range | Splunk UI picker | Dynatrace UI picker | Must match windows |

**Bottom line:** The approach for the *text* filters is reasonable. The approach for the *scope* is not a 1:1 transfer yet.

---

## 3) What the Splunk query should transfer to

Think in two layers:

| Layer | Splunk | Dynatrace goal |
| --- | --- | --- |
| A — Scope | `index=cs-digital-document-management` | All logs that belong to that app/index equivalent |
| B — Content | `error` + exclude `elivery not possible` | Same on `content` (and optionally other text fields) |

### Step A — Discover (run this first)

```dql
fetch logs
| filter contains(aws.log_group, "cs-digital-document-management")
   or contains(content, "cs-digital-document-management")
   or contains(log.source, "cs-digital-document-management")
| summarize count = count(), by: { aws.log_group, log.source, dt.entity.process_group, k8s.deployment.name }
| sort count desc
| limit 50
```

| Why | What you learn |
| --- | --- |
| Drop `-prod` for discovery | See stg/dev/other Lambdas if ingested |
| Group by log_group / source | What Dynatrace actually has for this app |
| Compare to Splunk | Which groups make up the old index |

### Step B — Closer scope transfer (typical AWS Lambda case)

If discovery shows several log groups for the app:

```dql
fetch logs
| filter contains(aws.log_group, "cs-digital-document-management")
| filter contains(content, "error", caseSensitive: false)
| filter not contains(content, "elivery not possible", caseSensitive: false)
| sort timestamp desc
| limit 1000
```

| Change vs your query | Why |
| --- | --- |
| Removed `-prod` and full `/aws/lambda/…` lock | Closer to “whole index” breadth |
| Kept error + exclude | Same content logic as Splunk |

If you **only** want prod (after you know Splunk was prod-only too):

```dql
fetch logs
| filter contains(aws.log_group, "cs-digital-document-management")
| filter contains(aws.log_group, "prod")
| filter contains(content, "error", caseSensitive: false)
| filter not contains(content, "elivery not possible", caseSensitive: false)
| sort timestamp desc
| limit 1000
```

### Step C — If logs are not only Lambda / `aws.log_group` is empty

Some pipelines land under other attributes. After discovery, pick what you saw:

```dql
fetch logs
| filter contains(log.source, "cs-digital-document-management")
   or contains(dt.source_entity.name, "cs-digital-document-management")
   or contains(k8s.deployment.name, "cs-digital-document-management")
| filter contains(content, "error", caseSensitive: false)
| filter not contains(content, "elivery not possible", caseSensitive: false)
| sort timestamp desc
| limit 1000
```

---

## 4) Field mapping cheat sheet

| Splunk | Dynatrace (usual) | Note |
| --- | --- | --- |
| `index=…` | Not a DQL field — map via `aws.log_group` / `log.source` / entity / namespace | Must discover |
| `_raw` / free-text `"error"` | `contains(content, "error")` | Close enough for most |
| `message="*error*"` | `contains(content, "error")` | If `message` was extracted, also try that attribute if present |
| `message!="*elivery…*"` | `not contains(content, "elivery not possible")` | Keep the same typo string to match Splunk |
| Time picker | Dynatrace time range | Align both UIs |

Optional stronger phrase match (when you want word-ish matching):

```dql
| filter matchesPhrase(content, "error")
| filter not matchesPhrase(content, "elivery not possible")
```

Use `contains` first to mirror Splunk `*error*` wildcards.

---

## 5) Other reasons counts still differ (after scope fix)

| Check | Why it matters |
| --- | --- |
| Same time window | Different UI ranges → different counts |
| Ingestion gap | Not every Splunk index event may be in Dynatrace yet |
| Sampling / processing | DT pipeline may drop or reshape lines |
| Case / field | You already used `caseSensitive: false` — good |
| Duplicate `"error"` in Splunk | Free-text + `message=*error*` is partly redundant; DQL one `contains` is fine |

---

## 6) Is “this approach” right?

| Part | Verdict |
| --- | --- |
| `fetch logs` + `contains(content,"error")` + exclude | **Yes** — good transfer of the message logic |
| Scope = only `…-prod` Lambda log group | **Not equal** to Splunk index — too narrow unless proven |
| Next action | Discover log groups, then widen filter to `cs-digital-document-management` (all matching groups) |

---

## Data flow map

```
Splunk index cs-digital-document-management
        │  (many sources / maybe many envs)
        ▼
   keyword "error" + message filters
        │
        ▼
   many rows

Your DQL:
fetch logs
  → ONLY aws.log_group …-prod     ← narrower bucket
  → content error / exclude
  → few rows

Better DQL:
fetch logs
  → discover groups for cs-digital-document-management
  → filter those groups (not only -prod)
  → same content filters
  → counts closer to Splunk
```

---

## Related files

| File | Role |
| --- | --- |
| `4-splunk-to-dql-scope-transfer.dql` | Copy-paste queries |
| `2026-09-18/2-dynatrace-log-query-how-to-top10/` | General DQL log how-to |
| `4.sh` | Optional helpers (user runs) |

## Commands

See `4.sh`.
