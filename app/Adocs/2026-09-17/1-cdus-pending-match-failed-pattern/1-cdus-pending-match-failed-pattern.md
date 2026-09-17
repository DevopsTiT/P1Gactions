# Cdus Pending Match Failed Pattern

```
Pic 1 = failed_uploads (correct DQL pattern)
Pic 2 = pending_uploads (was only listing rows)
  │
  └─ Change pic 2 search_query to use same stats-by-cmxDocumentId
       then filter: started > 0 and completed == 0 and failed == 0
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What was wrong | Pending alert listed log lines; it did not detect “started but not finished” |
| What pic 1 does | Count started/completed/failed per `cmxDocumentId`, then `filter failed > 0` |
| What pic 2 becomes | Same stats, then filter pending (started, no complete, no fail) |
| File | `cdus_backend_pending_uploads.tf` |

## Summary

Make the pending log alert use the same DQL shape as the failed alert. Keep pending name and description. Only replace the middle of `search_query` with `stats` + a pending filter.

---

## Investigation

| | Pic 1 (reference) | Pic 2 (change this) |
| --- | --- | --- |
| Resource | `cdus_backend_failed_uploads` | `cdus_backend_pending_uploads` |
| Alert name | HasDetectedFailedUploads_High | HasDetectedPendingUploads_High |
| DQL end | `stats` → `filter failed > 0` | was `fields` → `sort` → `limit` |
| Schedule | every 5 min, last 15 min | same (keep) |

## Result

Replace the pending `search_query` with the block below (also in `cdus_backend_pending_uploads.tf`).

---

## What to paste into pic 2

```hcl
search_query = <<-EOT
  fetch logs
  | filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
  | filter contains(content, "action:") and contains(content, "cmxDocumentId:")
  | parse content, "LD 'action:' WORD:action LD 'cmxDocumentId:' WORD:cmxDocumentId"
  | stats
      count(if(action == "UPLOAD_STARTED", 1, null)) as started,
      count(if(action == "UPLOAD_COMPLETED", 1, null)) as completed,
      count(if(action == "UPLOAD_FAILED", 1, null)) as failed,
      by: {cmxDocumentId}
  | filter started > 0 and completed == 0 and failed == 0
  | sort started desc
  | limit 100
EOT
```

### Diff vs pic 1 (failed)

| Step | Failed (pic 1) | Pending (pic 2 fixed) |
| --- | --- | --- |
| fetch / filter / parse | Same | Same |
| stats | Same three counts | Same three counts |
| filter | `failed > 0` | `started > 0 and completed == 0 and failed == 0` |
| sort | `failed desc` | `started desc` |

### Why this pending filter

| Condition | Meaning |
| --- | --- |
| `started > 0` | Upload began for that document id |
| `completed == 0` | Never saw UPLOAD_COMPLETED |
| `failed == 0` | Never saw UPLOAD_FAILED |

That matches the description: “uploads are pending and not completing.”

### Optional stricter pending

If one document can start many times:

```dql
| filter started > (completed + failed)
```

Use only if product owners agree.

---

## Leave unchanged on pic 2

| Field | Value |
| --- | --- |
| Resource name | `cdus_backend_pending_uploads` |
| alert_name | `Prod_Life_CDUS_Backend HasDetectedPendingUploads_High` |
| description | Alert when uploads are pending and not completing |
| cron / time_range / expires | `*/5`, `LAST_15_MINUTES`, `30` |
| trigger_conditions | Keep as already written in your file |

---

## Data flow map

```
Lambda logs (createDocumentAction)
  → parse action + cmxDocumentId
  → stats per document
       ├─ failed alert: failed > 0
       └─ pending alert: started, no complete, no fail
  → scheduled every 5 min / last 15 min
  → Dynatrace log alert → (your notify path)
```

## Related files

| Path | Why |
| --- | --- |
| `cdus_backend_pending_uploads.tf` | Full corrected resource stub |
| `1.sh` | Reminders |

## Commands

See `1.sh` in this folder.
