# Migrate Splunk "CCI_AWS_Batch Time Out" → Dynatrace
# Splunk: index=cci-fa-comm-calc "Task timed out" | search message!=*DEBUG*
#         cron */5, results > 0, trigger once, PagerDuty
# Dynatrace: log metric + metric_events (same shape as ContactManager MQ alerts)
# No variables — edit placeholders before apply.

terraform {
  required_providers {
    dynatrace = {
      source  = "dynatrace-oss/dynatrace"
      version = "~> 1.30.0"
    }
  }
}

provider "dynatrace" {
}

# -----------------------------------------------------------------------------
# Log metric ≈ Splunk search (count matching log lines)
# -----------------------------------------------------------------------------
resource "dynatrace_log_metrics" "cci_aws_batch_task_timed_out" {
  enabled = true
  key     = "log.cci.aws.batch.task_timed_out"
  measure = "OCCURRENCE"

  # Prefer scoped matcher (Lambda log group from migration sheet).
  # If aws.log_group is missing on records, use the alternate query below instead.
  query = "matchesPhrase(content, \"Task timed out\") and not matchesPhrase(content, \"DEBUG\") and matchesPhrase(aws.log_group, \"/aws/lambda/cci-fa-comm-calc\")"

  # Alternate (broader):
  # query = "matchesPhrase(content, \"Task timed out\") and not matchesPhrase(content, \"DEBUG\")"

  dimensions = ["host.name"]
}

# -----------------------------------------------------------------------------
# Critical alert ≈ Splunk: number of results > 0 every ~5 minutes
# -----------------------------------------------------------------------------
resource "dynatrace_metric_events" "alerting_cci_aws_batch_timeout_error" {
  enabled                    = true
  event_entity_dimension_key = "host.name"
  summary                    = "CCI_AWS_Batch Time Out Critical"

  event_template {
    description = "CCI FA Comm Calc Task timed out detected (current: {alert_condition:value}). Host: {dims:host.name}"
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
# Warning — ContactManager-style sustained signal (~10 min)
# -----------------------------------------------------------------------------
resource "dynatrace_metric_events" "alerting_cci_aws_batch_timeout_warning" {
  enabled                    = true
  event_entity_dimension_key = "host.name"
  summary                    = "CCI_AWS_Batch Time Out Warning"

  event_template {
    description = "CCI FA Comm Calc Task timed out sustained ~10min (current: {alert_condition:value}). Host: {dims:host.name}"
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

# PagerDuty: do NOT put the Splunk PD key here.
# Wire Dynatrace → Settings → Integration → Problem notifications → PagerDuty
# (or your existing ServiceNow / PD integration) for event_type ERROR.
