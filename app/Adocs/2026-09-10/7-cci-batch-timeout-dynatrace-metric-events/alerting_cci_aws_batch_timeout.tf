# CCI_AWS_Batch Time Out — Dynatrace Terraform
# Pattern: same structure as applications/contactmanager/test/alerting_contactmanager_mq.tf
# Source alert (Splunk): index=cci-fa-comm-calc "Task timed out" | search message!=*DEBUG*
#          cron */5, results > 0, trigger once → map to metric event ABOVE 0

# -----------------------------------------------------------------------------
# 1) Log metric (Grail log → metric) — required before metric_events
# -----------------------------------------------------------------------------
resource "dynatrace_log_metrics" "cci_aws_batch_task_timed_out" {
  enabled = true
  key     = "log.cci.aws.batch.task_timed_out"
  measure = "OCCURRENCE"

  # Matcher ≈ Splunk: "Task timed out" and not DEBUG, scoped to CCI Lambda log group when present
  query = "matchesPhrase(content, \"Task timed out\") and not matchesPhrase(content, \"DEBUG\") and matchesPhrase(aws.log_group, \"/aws/lambda/cci-fa-comm-calc\")"

  # Split like CM splitBy(queue.name) — use host for entity dimension
  dimensions = ["host.name"]
}

# If aws.log_group is not on your records, use this looser matcher instead (comment one query):
# query = "matchesPhrase(content, \"Task timed out\") and not matchesPhrase(content, \"DEBUG\")"

# -----------------------------------------------------------------------------
# 2) Critical — same shape as alerting_contactmanager_mq_*_error
# -----------------------------------------------------------------------------
resource "dynatrace_metric_events" "alerting_cci_aws_batch_timeout_error" {
  enabled                    = true
  event_entity_dimension_key = "host.name"
  summary                    = "CCI AWS Batch Time Out Critical"

  event_template {
    description = "CCI FA Comm Calc has Task timed out events (current: {alert_condition:value}). Host: {dims:host.name}"
    davis_merge = false
    event_type  = "ERROR"
    title       = "CCI_AWS_Batch Time Out - {dims:host.name}"
  }

  model_properties {
    type               = "STATIC_THRESHOLD"
    alert_condition    = "ABOVE"
    alert_on_no_data   = false
    dealerting_samples = 5
    samples            = 5
    threshold          = 0
    violating_samples  = 1
  }

  query_definition {
    type            = "METRIC_SELECTOR"
    metric_selector = "log.cci.aws.batch.task_timed_out:splitBy(\"host.name\"):sum"
  }

  depends_on = [dynatrace_log_metrics.cci_aws_batch_task_timed_out]
}

# -----------------------------------------------------------------------------
# 3) Warning — same shape as alerting_contactmanager_mq_*_warning
# -----------------------------------------------------------------------------
resource "dynatrace_metric_events" "alerting_cci_aws_batch_timeout_warning" {
  enabled                    = true
  event_entity_dimension_key = "host.name"
  summary                    = "CCI AWS Batch Time Out Warning"

  event_template {
    description = "CCI FA Comm Calc Task timed out is sustained for ~10min (current: {alert_condition:value}). Host: {dims:host.name}"
    davis_merge = false
    event_type  = "RESOURCE"
    title       = "CCI_AWS_Batch Time Out Warning - {dims:host.name}"
  }

  model_properties {
    type               = "STATIC_THRESHOLD"
    alert_condition    = "ABOVE"
    alert_on_no_data   = false
    dealerting_samples = 5
    samples            = 10
    threshold          = 0
    violating_samples  = 10
  }

  query_definition {
    type            = "METRIC_SELECTOR"
    metric_selector = "log.cci.aws.batch.task_timed_out:splitBy(\"host.name\"):sum"
  }

  depends_on = [dynatrace_log_metrics.cci_aws_batch_task_timed_out]
}
