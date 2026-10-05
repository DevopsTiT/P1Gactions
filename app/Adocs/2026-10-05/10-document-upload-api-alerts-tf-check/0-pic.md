# Document Upload API Alerts Check Pic

```
document-upload-api.tf (5 x dynatrace_log_alert → plan fails)
  PD key x5 in code          → remove, rotate, sensitive var
  1 Pending                  → BUG (matches all actions) → workflow: per document, started & not finished > 10m → event
  2 Failed                   → BUG (matches all actions) → detector, UPLOAD_FAILED only
  3 Database                 → detector (failed to init database, etimedout, econnrefused)
  4 CMX                      → detector (failed to create cmx document)
  5 Batch, throttle 8h       → detector, dealerting 60
  parse                      → SPACE? after 'action:', NSPACE for cmxDocumentId
  routing                    → one workflow for Prod_Life_CDUS_Backend* → PD (CDUS) + email
```
