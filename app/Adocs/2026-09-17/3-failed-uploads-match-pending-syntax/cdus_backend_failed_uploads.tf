# Pic 2 failed alert — match Pic 1 (pending) DQL syntax
# Keep resource name / alert_name / description for failed.
# Only search_query changes: drop stats; use filter + fields + sort like pending.

resource "dynatrace_log_alert" "cdus_backend_failed_uploads" {
  enabled     = true
  alert_name  = "Prod_Life_CDUS_Backend HasDetectedFailedUploads_High"
  description = "Alert when uploads have failed"

  # BEFORE (pic 2): stats by cmxDocumentId, filter failed > 0
  # AFTER  (like pic 1 pending): filter action, fields, sort timestamp, limit

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
