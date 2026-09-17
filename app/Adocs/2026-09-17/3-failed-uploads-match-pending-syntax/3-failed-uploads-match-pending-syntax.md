# Failed Uploads Match Pending Syntax

```
Pic 1 = pending_uploads (target syntax)
  filter action → fields → sort timestamp → limit
Pic 2 = failed_uploads (change this)
  was: stats → filter failed > 0
  become: same shape as pic 1, but action == UPLOAD_FAILED
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What to change | Pic 2 `search_query` only |
| Target syntax | Same as pic 1: parse → filter action → fields → sort → limit |
| Failed-specific line | `filter action == "UPLOAD_FAILED"` |
| Keep | alert name, description, cron, time_range, expires, triggers |

## Summary

Rewrite the failed-uploads DQL to use the same pipeline style as pending-uploads. Drop the `stats` aggregation. Alert on raw `UPLOAD_FAILED` log rows instead.

---

## Investigation

| | Pic 1 (keep style) | Pic 2 (change) |
| --- | --- | --- |
| Resource | `cdus_backend_pending_uploads` | `cdus_backend_failed_uploads` |
| After parse | `filter action == STARTED or COMPLETED or FAILED` | was `stats` + `filter failed > 0` |
| Output | `fields` + `sort timestamp desc` | should match that shape |
| Schedule | every 5 min / last 15 min | keep the same |

## Result

Paste the `search_query` below into pic 2 (full resource in `cdus_backend_failed_uploads.tf`).

---

## What to paste into pic 2

```hcl
search_query = <<-EOT
  fetch logs
  | filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
  | filter contains(content, "action:") and contains(content, "cmxDocumentId:")
  | parse content, "LD 'action:' WORD:action LD 'cmxDocumentId:' WORD:cmxDocumentId"
  | filter action == "UPLOAD_FAILED"
  | fields timestamp, action, cmxDocumentId
  | sort timestamp desc
  | limit 100
EOT
```

### Side-by-side syntax

| Step | Pic 1 pending | Pic 2 failed (fixed) |
| --- | --- | --- |
| fetch / log group / content / parse | Same | Same |
| action filter | STARTED or COMPLETED or FAILED | `UPLOAD_FAILED` only |
| next | `fields timestamp, action, cmxDocumentId` | Same |
| sort | `timestamp desc` | Same |
| limit | `100` | Same |

### Why not keep `stats` on failed

You asked pic 2 to **match pic 1 syntax**. Pic 1 lists matching log rows. Pic 2 now lists failed rows the same way. Trigger on `NUMBER_OF_RESULTS` still works: any failed row in the window fires the alert.

### Optional: exact same three-action filter as pic 1

Only if you want the filter line identical and rely on something else to mean “failed” (usually worse):

```dql
| filter action == "UPLOAD_STARTED" or action == "UPLOAD_COMPLETED" or action == "UPLOAD_FAILED"
```

Prefer `action == "UPLOAD_FAILED"` for a failed alert.

---

## Full resource (copy/paste)

See `cdus_backend_failed_uploads.tf` in this folder.

---

## Data flow map

```
Lambda logs (createDocumentAction)
  → filter + parse action / cmxDocumentId
  → filter UPLOAD_FAILED          ← only difference vs listing all actions
  → fields + sort + limit         ← same syntax as pic 1
  → scheduled log alert (every 5 min / last 15 min)
```

## Related files

| Path | Why |
| --- | --- |
| `cdus_backend_failed_uploads.tf` | Fixed Terraform |
| `../1-cdus-pending-match-failed-pattern/` | Earlier reverse direction (pending→stats); ignore if you want fields style |
| `3.sh` | Paths |

## Commands

See `3.sh` in this folder.
