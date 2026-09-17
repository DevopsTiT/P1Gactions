# Pic 2 pending alert — match Pic 1 (failed) DQL pattern
# Keep resource name / alert_name / description for pending.
# Only search_query (and sort) change to use stats like failed_uploads.

resource "dynatrace_log_alert" "cdus_backend_pending_uploads" {
  enabled     = true
  alert_name  = "Prod_Life_CDUS_Backend HasDetectedPendingUploads_High"
  description = "Alert when uploads are pending and not completing"

  # BEFORE (pic 2 — wrong for "pending"): listed raw rows only
  # AFTER  (like pic 1 failed): stats by cmxDocumentId, then filter pending

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

  alert_type      = "SCHEDULED"
  schedule_type   = "CUSTOM"
  cron_expression = "*/5 * * * *"
  time_range      = "LAST_15_MINUTES"
  expires         = 30

  # Keep your existing trigger_conditions block below (same as before).
  # Example shape if you need to recreate it:
  # trigger_conditions {
  #   trigger_alert_when = "NUMBER_OF_RESULTS"
  #   ...
  # }
}
