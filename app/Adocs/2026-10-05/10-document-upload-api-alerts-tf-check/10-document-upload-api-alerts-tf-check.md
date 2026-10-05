# Document Upload API Alerts Terraform Check

## Decision tree

```
document-upload-api.tf (5 alerts, all dynatrace_log_alert)
 resource exists?                              → NO → plan fails
 PagerDuty integration_key in all 5            → SECRET in code → remove, rotate if pushed, pass as sensitive var
 different PD key from the SILVA workflow      → these need their own routing (CDUS PagerDuty service)

 ALERT 1 Pending uploads
   query keeps STARTED or COMPLETED or FAILED → LOGIC BUG: fires on every upload, not on pending ones
   real "pending" = STARTED with no finish   → per-document check → scheduled workflow + Davis event
 ALERT 2 Failed uploads
   same filter (all 3 actions)                → LOGIC BUG: fires on every upload → keep only UPLOAD_FAILED
 ALERT 3 Database errors                      → OK logic → detector, case-insensitive
 ALERT 4 CMX errors                           → OK logic → detector
 ALERT 5 Batch errors, throttle 8 hours       → OK logic → detector, dealerting 60 (8h suppression not exact)

 parse pattern
   WORD for cmxDocumentId                     → stops at "-", so UUIDs get cut → use NSPACE
   'action:' then WORD                        → fails if there is a space → add SPACE?
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. All 5 use `dynatrace_log_alert`, which does not exist |
| Secret | The CDUS PagerDuty key is hard-coded 5 times |
| Biggest logic issue | Alerts 1 and 2 match all three actions, so both fire on every normal upload |
| Alerts 3, 4, 5 | Logic is fine; convert to detectors |
| Routing | Separate workflow for `Prod_Life_CDUS_Backend` problems with the CDUS PagerDuty key and email |

## Summary

This file is already half DQL (the `parse` with `LD` and `WORD` is Dynatrace syntax), but it still uses the non-existent resource and Splunk-style triggers. Two alerts have real logic bugs. "Pending uploads" and "Failed uploads" both keep rows where the action is STARTED **or** COMPLETED **or** FAILED, so any normal upload makes both fire. Failed should keep only `UPLOAD_FAILED`, and Pending needs a per-document check (started, never finished). The PagerDuty key is also in plain text five times, and it's a different PagerDuty service from your SILVA workflow, so CDUS needs its own routing workflow.

## Problems found

| Problem | Where | Why it matters | Fix |
|---|---|---|---|
| Resource does not exist | All 5 | `terraform plan` fails | Detectors and workflows (see file) |
| PagerDuty key in plain text | All 5 | Anyone with repo access can page the CDUS on-call; stays in Git history | Remove; rotate if pushed; `variable "cdus_pagerduty_routing_key"` with `sensitive = true` from a CI secret |
| Pending alert matches all actions | Alert 1 | Fires on every upload; never really detects "stuck" | Per-document check: started, no completed or failed after 10 minutes |
| Failed alert matches all actions | Alert 2 | Fires on every upload | `filter action == "UPLOAD_FAILED"` |
| `WORD:cmxDocumentId` | Alerts 1, 2 | `WORD` stops at `-`, so an id like `ab12-cd34` becomes `ab12` | `NSPACE:cmxDocumentId` |
| `'action:' WORD` with no space allowance | Alerts 1, 2 | If the log says `action: UPLOAD_FAILED`, the parse returns nothing | `'action:' SPACE? WORD:action` |
| `contains(aws.log_group, ".../document-upload-api-prod")` | Alerts 3, 4, 5 | Matches every log group starting with that name, including `-createDocumentAction` and the workers | Fine if intended; `startsWith` makes that explicit |
| Window 15 minutes, runs every 5 | All 5 | In Splunk the same error was emailed up to 3 times | Dynatrace keeps one problem open; window 5 is enough |
| Throttle 8 hours | Alert 5 | Dynatrace can't hold a problem quiet for 8 hours | `dealertingSamples` as high as allowed (60 in the file); accept or discuss |
| Case | 3, 4, 5 | Splunk ignored case | `lower(content)` or `caseSensitive: false` |

## Alert by alert

| # | Name | Converted to | Key settings |
|---|---|---|---|
| 1 | HasDetectedPendingUploads_High | Scheduled workflow every 5 min: DQL per document, JavaScript raises CUSTOM_ALERT if any | Pending = started more than 10 min ago with no finish; look back 60 min |
| 2 | HasDetectedFailedUploads_High | Detector | Only `UPLOAD_FAILED`; window 5; dealerting 15 |
| 3 | HasDetectedDatabaseErrors_High | Detector | "failed to init database", "etimedout", "econnrefused" (any case) |
| 4 | HasDetectedCMXErrors_High | Detector | "Failed to create CMX Document" (any case) |
| 5 | HasDetectedBatchError_High | Detector | Worker log groups and "error report" or "exiterror"; dealerting 60 |

Alerts 2 to 5 share one `for_each` block in the `.tf` file, so each is just a title, description, dealerting and query.

## Alert 1 — the pending query

```dql
fetch logs, from:now()-60m
| filter aws.log_group == "/aws/lambda/document-upload-api-prod-createDocumentAction"
| filter contains(content, "action:") and contains(content, "cmxDocumentId:")
| parse content, "LD 'action:' SPACE? WORD:action LD 'cmxDocumentId:' SPACE? NSPACE:cmxDocumentId"
| filter in(action, array("UPLOAD_STARTED", "UPLOAD_COMPLETED", "UPLOAD_FAILED"))
| summarize started = countIf(action == "UPLOAD_STARTED"),
            finished = countIf(action == "UPLOAD_COMPLETED" or action == "UPLOAD_FAILED"),
            firstStart = min(timestamp),
            by:{cmxDocumentId}
| filter started > 0 and finished == 0 and firstStart < now() - 10m
```

| Part | What it does |
|---|---|
| `from:now()-60m` | Looks back far enough to see both the start and the finish |
| `summarize ... by:{cmxDocumentId}` | One row per document |
| `finished == 0` | Never completed or failed |
| `firstStart < now() - 10m` | Started more than 10 minutes ago, so it is really stuck (agree the number with the team) |

The workflow then runs a short JavaScript task that raises a `CUSTOM_ALERT` event titled `Prod_Life_CDUS_Backend HasDetectedPendingUploads_High` with the count and up to 20 document ids. While documents stay stuck, each run refreshes the same event; when none are left, the event times out after 15 minutes and the problem closes.

## Check the parse before apply

```dql
fetch logs, from:-1d
| filter aws.log_group == "/aws/lambda/document-upload-api-prod-createDocumentAction"
| filter contains(content, "action:") and contains(content, "cmxDocumentId:")
| parse content, "LD 'action:' SPACE? WORD:action LD 'cmxDocumentId:' SPACE? NSPACE:cmxDocumentId"
| fields timestamp, action, cmxDocumentId, content
| limit 20
```

| What you see | Fix |
|---|---|
| `action` and `cmxDocumentId` filled | Good |
| `cmxDocumentId` ends with a quote or comma | The log is JSON-like; tell me a sample line and I'll adjust the pattern |
| Both empty | The text isn't `action:`; it may be `"action":`; share a sample |

## Routing

| Item | Old | New |
|---|---|---|
| Problem severity HIGH | `DYNATRACE_PROBLEM` HIGH | Detector or event opens the problem; `alert.severity = high` property |
| PagerDuty | CDUS key in each alert | One routing workflow for every problem whose name starts with `Prod_Life_CDUS_Backend`, key from a sensitive variable |
| Email | Each alert | Same routing workflow, subject `[PROD] Alert: <problem name>` |
| Your SILVA OPEN workflow | Not involved before | Decide whether CDUS problems should also create SILVA tickets; if not, exclude names starting with `Prod_Life_CDUS_Backend` |

Even as a sensitive variable, the key ends up inside the workflow definition in Dynatrace. Storing it in the Dynatrace credential vault and reading it in a JavaScript task is safer; do that if your team already uses the vault.

## Data flow

```
document-upload-api-prod Lambdas
  → CloudWatch log groups (/aws/lambda/document-upload-api-prod*)
  → Dynatrace AWS log forwarding → Grail
  ALERT 1: every 5 min workflow → DQL per cmxDocumentId → stuck > 10 min? → CUSTOM_ALERT event
  ALERTS 2-5: detectors every minute → count > 0 in window 5 → CUSTOM_ALERT event
  → Problem "Prod_Life_CDUS_Backend ..."
  → CDUS routing workflow → PagerDuty (CDUS key) + email new_business and bam
  → quiet period → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Six screenshots of `document-upload-api.tf` | 5 `dynatrace_log_alert` resources |
| Alerts 1 and 2 | Identical queries keeping all three actions; titles say pending and failed |
| Alerts 3 to 5 | Reasonable string filters; Alert 5 throttles 8 hours |
| Actions | Each has a Dynatrace problem HIGH, a PagerDuty action with the same key, and email to 2 lists |
| PagerDuty key | Hard-coded 5 times; different from the SILVA workflow key |
| Provider docs | Detectors, workflows with schedule and problem triggers, JavaScript and HTTP tasks are all supported |

## Result

Not OK as is. Fix the two logic bugs (pending needs a per-document check; failed should keep only `UPLOAD_FAILED`), move the PagerDuty key out of the file (rotate if pushed), convert alerts 2 to 5 to detectors, build alert 1 as a scheduled workflow, and add one CDUS routing workflow for PagerDuty and email. Check the parse pattern with a real log line first.

## Related files

| File | Purpose |
|---|---|
| `10-document-upload-api-alerts-tf-check-main.tf` | All 5 alerts, pending workflow, CDUS routing workflow |
| `10.sh` | Secret search, validate, plan with the key from env, mirror and git one-liners |
| `2026-10-05/6-cci-batch-timeout-alert-tf-check/` | Earlier note on hard-coded PagerDuty keys |

## Commands

See `10.sh` (not run).
