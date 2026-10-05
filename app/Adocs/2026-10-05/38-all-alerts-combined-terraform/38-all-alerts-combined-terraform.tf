# ==========================================================================
# All Dynatrace alerts written on 2026-10-05 (seq 5 to 36) in one file
#
# Latest version only for each alert:
#   Cisco VPN LDAP   → seq 22 (inline, replaces seq 4 and seq 21)
#   OUD restart      → seq 26 (Terraform only, replaces seq 25)
#   Control-M        → seq 31 (v2, replaces seq 30)
#   "house-style" dynatrace_log_alert files (seq 21, 25) are not included.
#
# Part 1: log_alert → Davis detector conversions (seq 5 to 20)
#   seq 5   Compass BigData Glue skip            seq 13  HPM SharePoint API Lambda error
#   seq 6   CCI AWS Batch timeout                seq 14  HPM SurveyMonkey Lambda error
#   seq 7   HPM CMX to SharePoint Lambda error   seq 15  BRE InnoRules (PagerDuty variable)
#   seq 8   CS Digital Document Management       seq 16  Emma MsgBox errors
#   seq 9   Customer Process API                 seq 17  Emma onboarding batch
#   seq 10  Document Upload API (PD variable)    seq 18  PMT API
#   seq 11  eOPT serverless                      seq 19  RecruitIMP serverless
#   seq 12  Gov inquiry system                   seq 20  SA support batches
#
# Part 2: Cisco VPN LDAP (seq 22) and OUD restart failed (seq 26)
#
# Part 3: Splunk → Dynatrace migration (seq 27, 28, 29, 31, 32, 34, 35, 36)
#
# Fixes applied here versus the original seq files (originals left unchanged):
#   seq 35  event.description used "{violating_samples}", which is not a Dynatrace placeholder → removed
#   seq 35  added arrayMovingMax(responsetime, 10) so a job that does not log every minute
#           can still reach 5 violating minutes (same idea as Splunk's 10-minute max)
#
# Secrets: none in this file. Two PagerDuty routing keys are sensitive variables:
#   var.cdus_pagerduty_routing_key (seq 10), var.bre_pagerduty_routing_key (seq 15)
#   Pass them with TF_VAR_cdus_pagerduty_routing_key / TF_VAR_bre_pagerduty_routing_key from a CI secret.
#
# Every section still has its own CONFIRM notes. Run each seq's check.dql before apply.
# ==========================================================================

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

# Auth comes from env vars: DT_ENV_URL plus DT_PLATFORM_TOKEN (or DT_CLIENT_ID, DT_CLIENT_SECRET, DT_ACCOUNT_ID)
provider "dynatrace" {}


# ##########################################################################
# SECTION: 5-compass-glue-skip-alert-tf-review/5-compass-glue-skip-alert-tf-review-main.tf
# ##########################################################################

# ALERT: Prod_Life_Compass_BigData連動Glue_Skip発生
# Option A: count-based custom alert (same idea as the Splunk/CloudWatch schedule)

resource "dynatrace_davis_anomaly_detectors" "compass_bigdata_glue_skip" {
  title       = "Prod_Life_Compass_BigData連動Glue_Skip発生"
  description = "Glue job compass-sales-performance logged 'skipping table' in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws-glue/jobs/custom/compass-sales-performance"
          | filter contains(content, "skipping table")
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_Life_Compass_BigData連動Glue_Skip発生"
      }
      property {
        key   = "event.description"
        value = "Glue job compass-sales-performance logged 'skipping table'. Log group /aws-glue/jobs/custom/compass-sales-performance."
      }
      property {
        key   = "alert.priority"
        value = "normal"
      }
      property {
        key   = "alert.notify"
        value = "yuta.inoue@axa.co.jp,shihao.he@axa.co.jp"
      }
    }
  }

  execution_settings {}
}

# Option B: one event per matching log line (classic log events, simpler, API token works)
resource "dynatrace_log_events" "compass_bigdata_glue_skip_line" {
  enabled = false
  summary = "Prod_Life_Compass_BigData連動Glue_Skip発生"
  query   = "matchesValue(aws.log_group, \"/aws-glue/jobs/custom/compass-sales-performance\") and matchesPhrase(content, \"skipping table\")"

  event_template {
    title       = "Prod_Life_Compass_BigData連動Glue_Skip発生"
    description = "{content}"
    event_type  = "CUSTOM_ALERT"
  }
}

# ##########################################################################
# SECTION: 6-cci-batch-timeout-alert-tf-check/6-cci-batch-timeout-alert-tf-check-main.tf
# ##########################################################################

# ALERT: CCI_AWS_Batch Time Out
# Lambda cci-fa-comm-calc logged "Task timed out" (DEBUG lines excluded)

resource "dynatrace_davis_anomaly_detectors" "cci_aws_batch_timeout" {
  title       = "CCI_AWS_Batch Time Out"
  description = "Lambda cci-fa-comm-calc logged 'Task timed out' in the last 5 minutes. CCI AWS Batch Task Timeout Alert."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/cci-fa-comm-calc"
          | filter contains(content, "Task timed out")
          | filter not contains(content, "!DEBUG!")
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "CCI_AWS_Batch Time Out"
      }
      property {
        key   = "event.description"
        value = "CCI AWS Batch Task Timeout Alert. Lambda /aws/lambda/cci-fa-comm-calc logged 'Task timed out'."
      }
    }
  }

  execution_settings {}
}

# Option B: one event per matching line (classic API token is enough)
resource "dynatrace_log_events" "cci_aws_batch_timeout_line" {
  enabled = false
  summary = "CCI_AWS_Batch Time Out"
  query   = "matchesValue(aws.log_group, \"/aws/lambda/cci-fa-comm-calc\") and matchesPhrase(content, \"Task timed out\") and not matchesPhrase(content, \"!DEBUG!\")"

  event_template {
    title       = "CCI_AWS_Batch Time Out"
    description = "{content}"
    event_type  = "CUSTOM_ALERT"
  }
}

# ##########################################################################
# SECTION: 7-hpm-cmx-sharepoint-alert-tf-check/7-hpm-cmx-sharepoint-alert-tf-check-main.tf
# ##########################################################################

# ALERT: Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal
# Lambda cmx-sharepoint-api-prod logged an error while transferring files from CMX to SharePoint

resource "dynatrace_davis_anomaly_detectors" "hpm_cmx_to_sharepoint_api_lambda_error" {
  title       = "Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal"
  description = "To check Lambda error: failure transferring files from CMX to SharePoint (cmx-sharepoint-api-prod)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/cmx-sharepoint-api-prod"
          | filter contains(content, "Error", caseSensitive: false)
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "60"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal"
      }
      property {
        key   = "event.description"
        value = "Lambda /aws/lambda/cmx-sharepoint-api-prod logged an error. Failure transferring files from CMX to SharePoint."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: 8-cs-digital-document-alerts-tf-check/8-cs-digital-document-alerts-tf-check-main.tf
# ##########################################################################

# ============================================================
# ALERT 1: [CSDDM] Send alert email when Claims API fails
# Daily digest at 10:00 JST over the last 24 hours, so it is a scheduled workflow, not an anomaly detector
# ============================================================

resource "dynatrace_automation_workflow" "csddm_claims_api_fails" {
  title       = "[CSDDM] Send alert email when Claims API fails"
  description = "Every day at 10:00 JST, count 'claims api call failed' in cs-digital-document-management-prod over the last 24 hours and email if more than 0."

  tasks {
    task {
      name        = "count_failures"
      description = "Count Claims API failures in the last 24 hours"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          | filter aws.log_group == "/aws/lambda/cs-digital-document-management-prod"
          | filter contains(content, "claims api call failed", caseSensitive: false)
          | summarize failures = count()
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the team when failures were found"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "honlun.chan@axa.co.jp",
          "masaya.okuno@axa.co.jp",
          "aij_jp_dl_incident_claims_it@axa.co.jp",
          "axa_jp_dl_claims_transformation@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Alert: [CSDDM] Send alert email when Claims API fails"
        content = "Claims API call failed {{ result(\"count_failures\").records[0].failures }} time(s) in the last 24 hours.\nLog group: /aws/lambda/cs-digital-document-management-prod"
      })
      conditions {
        states = {
          count_failures = "SUCCESS"
        }
        custom = "{{ result(\"count_failures\").records[0].failures > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "0 10 * * *"
      }
    }
  }
}

# ============================================================
# ALERT 2: CS Digital Document Management Error alerts
# Every 5 minutes, any "error" except "delivery not possible", throttle 1 hour
# ============================================================

resource "dynatrace_davis_anomaly_detectors" "cs_digital_document_management_error" {
  title       = "CS Digital Document Management Error alerts"
  description = "Alerts when an error occurs. Github Repo: cs-digital-document-management"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/cs-digital-document-management-prod"
          | filter contains(content, "error", caseSensitive: false)
          | filter not contains(content, "delivery not possible", caseSensitive: false)
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "60"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "CS Digital Document Management Error alerts"
      }
      property {
        key   = "event.description"
        value = "Error logged by /aws/lambda/cs-digital-document-management-prod (excluding 'delivery not possible'). Github Repo: cs-digital-document-management"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "cs_digital_document_management_error_email" {
  title       = "CS Digital Document Management Error alerts - email"
  description = "Emails the team when the CS Digital Document Management Error alerts problem opens."

  tasks {
    task {
      name        = "send_email"
      description = "Email the team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["aij_jp_dl_csdigitaldocument@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Alert: CS Digital Document Management Error alerts"
        content = "Problem {{ event()[\"display_id\"] }} opened: {{ event()[\"event.name\"] }}\nLog group: /aws/lambda/cs-digital-document-management-prod"
      })
      position {
        x = 0
        y = 1
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "matchesPhrase(event.name, \"CS Digital Document Management Error alerts\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 9-customer-process-api-alerts-tf-check/9-customer-process-api-alerts-tf-check-main.tf
# ##########################################################################

# ============================================================
# ALERT 1: Customer Process API Success Request Monitoring
# Not a failure: an every-5-minutes notice of successful (201) requests.
# A scheduled workflow sends the email, so no Davis problem (and no SILVA/PagerDuty) is created.
# ============================================================

resource "dynatrace_automation_workflow" "customer_process_api_success_monitoring" {
  title       = "Customer Process API Success Request Monitoring"
  description = "To immediately understand the actual production contract requested and confirm operations."

  tasks {
    task {
      name        = "find_success"
      description = "201 responses from customer-process-api-prod in the last 5 minutes (shifted 1 minute for ingest delay)"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-6m, to:now()-1m
          | filter aws.log_group == "/aws/lambda/customer-process-api-prod"
          | filter contains(content, "\"statusCode\":201")
          | fields timestamp, aws.log_group, content
          | sort timestamp desc
          | limit 100
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the team when there were successful requests"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "iori.baba@axa.co.jp",
          "ryo.masuda@axa.co.jp",
          "naoki.takuda@axa.co.jp",
          "akito.matsumoto.ose@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "!!PROD!! Alert: Customer Process API Success Request Monitoring"
        content = "{{ result(\"find_success\").records | length }} successful request(s) in the last 5 minutes.\n\n{% for r in result(\"find_success\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          find_success = "SUCCESS"
        }
        custom = "{{ result(\"find_success\").records | length > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "*/5 * * * *"
      }
    }
  }
}

# ============================================================
# ALERT 2: Customer Process API Alerts
# Any of 9 known failure messages in the last 5 minutes
# ============================================================

resource "dynatrace_davis_anomaly_detectors" "customer_process_api_alerts" {
  title       = "Customer Process API Alerts"
  description = "Known failure messages from Lambda customer-process-api-prod (timeouts, unhandled errors, ineligible policy, IBL0250002, too many connections)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/customer-process-api-prod"
          | fieldsAdd c = lower(content)
          | filter contains(c, "task timed out")
              or contains(c, "an error occurred")
              or contains(c, "failed to handle: lifejdata")
              or contains(c, "got unexpected investment company code")
              or contains(c, "the policy is ineligible for creating a request")
              or contains(c, "ibl0250002")
              or contains(c, "<statuscd>eb")
              or contains(c, "imported a total of 0 data")
              or contains(c, "handler error: too many connections")
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Customer Process API Alerts"
      }
      property {
        key   = "event.description"
        value = "Known failure message logged by /aws/lambda/customer-process-api-prod."
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "customer_process_api_alerts_email" {
  title       = "Customer Process API Alerts - email"
  description = "Emails the ADEPT team when the Customer Process API Alerts problem opens."

  tasks {
    task {
      name        = "send_email"
      description = "Email the team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["aij_jp_dl_adept@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "!!PROD!! Alert: Customer Process API Alerts"
        content = "Problem {{ event()[\"display_id\"] }} opened: {{ event()[\"event.name\"] }}\nLog group: /aws/lambda/customer-process-api-prod"
      })
      position {
        x = 0
        y = 1
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "matchesPhrase(event.name, \"Customer Process API Alerts\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 10-document-upload-api-alerts-tf-check/10-document-upload-api-alerts-tf-check-main.tf
# ##########################################################################

# document-upload-api (CDUS backend) alerts, converted from dynatrace_log_alert

variable "cdus_pagerduty_routing_key" {
  description = "PagerDuty Events v2 routing key for the CDUS service. Pass from a CI secret, never commit."
  type        = string
  sensitive   = true
}

locals {
  cdus_prefix = "/aws/lambda/document-upload-api-prod"

  cdus_detectors = {
    failed_uploads = {
      title       = "Prod_Life_CDUS_Backend HasDetectedFailedUploads_High"
      description = "Alert when uploads have failed"
      dealerting  = "15"
      query       = <<-EOT
        fetch logs
        | filter aws.log_group == "/aws/lambda/document-upload-api-prod-createDocumentAction"
        | filter contains(content, "action:") and contains(content, "cmxDocumentId:")
        | parse content, "LD 'action:' SPACE? WORD:action"
        | filter action == "UPLOAD_FAILED"
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
    }
    database_errors = {
      title       = "Prod_Life_CDUS_Backend HasDetectedDatabaseErrors_High"
      description = "Alert when database connection errors occur"
      dealerting  = "15"
      query       = <<-EOT
        fetch logs
        | filter startsWith(aws.log_group, "/aws/lambda/document-upload-api-prod")
        | fieldsAdd c = lower(content)
        | filter contains(c, "failed to init database")
            or contains(c, "etimedout")
            or contains(c, "econnrefused")
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
    }
    cmx_errors = {
      title       = "Prod_Life_CDUS_Backend HasDetectedCMXErrors_High"
      description = "Alert when CMX document creation fails"
      dealerting  = "15"
      query       = <<-EOT
        fetch logs
        | filter startsWith(aws.log_group, "/aws/lambda/document-upload-api-prod")
        | filter contains(content, "Failed to create CMX Document", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
    }
    batch_error = {
      title       = "Prod_Life_CDUS_Backend HasDetectedBatchError_High"
      description = "Alert when batch processing errors occur"
      dealerting  = "60"
      query       = <<-EOT
        fetch logs
        | filter startsWith(aws.log_group, "/aws/lambda/document-upload-api-prod")
        | filter contains(aws.log_group, "uploadOcr")
            or contains(aws.log_group, "Worker")
            or contains(aws.log_group, "rpaBatchProcess")
            or contains(aws.log_group, "uploadBankAccountScannedImage")
            or contains(aws.log_group, "uploadBankAccountCSVToIFT")
            or contains(aws.log_group, "uploadBankAccountCameraImage")
        | fieldsAdd c = lower(content)
        | filter contains(c, "error report") or contains(c, "exiterror")
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
    }
  }
}

# ALERTS 2 to 5: count-based detectors
resource "dynatrace_davis_anomaly_detectors" "cdus" {
  for_each = local.cdus_detectors

  title       = each.value.title
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = each.value.dealerting
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = each.value.title
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "alert.team"
        value = "cdus"
      }
    }
  }

  execution_settings {}
}

# ALERT 1: Pending uploads = STARTED with no COMPLETED or FAILED after 10 minutes
# Needs per-document logic, so a scheduled workflow runs the check and raises a Davis event
resource "dynatrace_automation_workflow" "cdus_pending_uploads" {
  title       = "Prod_Life_CDUS_Backend HasDetectedPendingUploads_High"
  description = "Every 5 minutes: uploads started more than 10 minutes ago with no COMPLETED or FAILED. Raises a CUSTOM_ALERT event when any are found."

  tasks {
    task {
      name        = "find_pending"
      description = "Documents started but not finished"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
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
          | sort firstStart asc
          | limit 100
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "raise_event"
      description = "Open or refresh the pending-uploads problem"
      action      = "dynatrace.automations:run-javascript"
      active      = true
      input = jsonencode({
        script = <<-EOT
          import { execution } from '@dynatrace-sdk/automation-utils';
          import { eventsClient } from '@dynatrace-sdk/client-classic-environment-v2';

          export default async function ({ execution_id }) {
            const ex = await execution(execution_id);
            const res = await ex.result('find_pending');
            const rows = (res && res.records) || [];
            if (rows.length === 0) return { pending: 0 };

            const ids = rows.slice(0, 20).map(r => r.cmxDocumentId).join(', ');
            await eventsClient.createEvent({
              body: {
                eventType: 'CUSTOM_ALERT',
                title: 'Prod_Life_CDUS_Backend HasDetectedPendingUploads_High',
                timeout: 15,
                properties: {
                  'alert.severity': 'high',
                  'alert.team': 'cdus',
                  'pending.count': String(rows.length),
                  'pending.ids': ids,
                },
              },
            });
            return { pending: rows.length, ids };
          }
        EOT
      })
      conditions {
        states = {
          find_pending = "SUCCESS"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "*/5 * * * *"
      }
    }
  }
}

# Routing for all 5 CDUS problems: PagerDuty (CDUS service) + email
resource "dynatrace_automation_workflow" "cdus_routing" {
  title       = "Prod_Life_CDUS_Backend - PagerDuty and email"
  description = "Sends every Prod_Life_CDUS_Backend problem to the CDUS PagerDuty service and emails the business teams."

  tasks {
    task {
      name        = "pagerduty_trigger"
      description = "PagerDuty Events v2 trigger for the CDUS service"
      action      = "dynatrace.automations:http-function"
      active      = true
      input = jsonencode({
        method = "POST"
        url    = "https://events.pagerduty.com/v2/enqueue"
        headers = {
          "Content-Type" = "application/json"
        }
        payload = jsonencode({
          routing_key  = var.cdus_pagerduty_routing_key
          event_action = "trigger"
          dedup_key    = "dt-problem-{{ event()[\"display_id\"] }}"
          payload = {
            summary  = "{{ event()[\"event.name\"] }}"
            source   = "document-upload-api-prod"
            severity = "error"
            custom_details = {
              problem_id = "{{ event()[\"display_id\"] }}"
            }
          }
        })
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the business teams"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "axa_jp_dl_new_business@axa.co.jp",
          "axa_jp_dl_bam@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "[PROD] Alert: {{ event()[\"event.name\"] }}"
        content = "Problem {{ event()[\"display_id\"] }} opened: {{ event()[\"event.name\"] }}\nService: document-upload-api-prod"
      })
      position {
        x = 1
        y = 1
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "startsWith(event.name, \"Prod_Life_CDUS_Backend\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 11-eopt-serverless-alerts-tf-check/11-eopt-serverless-alerts-tf-check-main.tf
# ##########################################################################

# eopt-serverless alerts, converted from dynatrace_log_alert

locals {
  eopt_log_group = "/aws/lambda/eopt-serverless-prod"

  # Lambda default line: 2026-10-05T01:02:03.456Z<TAB>request-id<TAB>ERROR<TAB>message
  # Swap for "| filter loglevel == \"ERROR\"" if the check query shows Dynatrace already sets loglevel
  eopt_error_filter = <<-EOT
    | parse content, "LD '-' LD '-' LD '-' LD '-' LD SPACE WORD:level"
    | filter level == "ERROR"
  EOT

  eopt_base = <<-EOT
    fetch logs
    | filter startsWith(aws.log_group, "${local.eopt_log_group}")
    ${local.eopt_error_filter}
  EOT
}

# ============================================================
# ALERT 1: E-Tool Error Lambda (Filtered Output)
# Every 5 minutes, any ERROR line → problem → email with timestamp, level, message
# ============================================================

resource "dynatrace_davis_anomaly_detectors" "etool_error_lambda" {
  title       = "E-Tool Error Lambda"
  description = "ERROR lines from Lambda eopt-serverless-prod."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = "${local.eopt_base}| makeTimeseries count = count(default: 0), interval:1m"
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "E-Tool Error Lambda"
      }
      property {
        key   = "event.description"
        value = "ERROR lines from Lambda eopt-serverless-prod."
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "etool_error_lambda_email" {
  title       = "E-Tool Error Lambda - email"
  description = "When the E-Tool Error Lambda problem opens, email the recent ERROR lines (timestamp, level, message)."

  tasks {
    task {
      name        = "recent_errors"
      description = "ERROR lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = "${replace(local.eopt_base, "fetch logs", "fetch logs, from:now()-10m")}| fields timestamp, level, content\n| sort timestamp desc\n| limit 100"
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email E-Tool maintenance"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["aij_jp_dl_etool_maintenance@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Alert: E-Tool Error Lambda"
        content = "Problem {{ event()[\"display_id\"] }}: ERROR lines from eopt-serverless-prod\n\n{% for r in result(\"recent_errors\").records %}{{ r.timestamp }}  {{ r.level }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_errors = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "matchesPhrase(event.name, \"E-Tool Error Lambda\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ============================================================
# ALERT 2: eopt - AWS Serverless Error (Full Output)
# Daily digest at 10:00 JST over the last 24 hours, so a scheduled workflow
# ============================================================

resource "dynatrace_automation_workflow" "eopt_aws_serverless_error" {
  title       = "eopt - AWS Serverless Error"
  description = "Every day at 10:00 JST, email all ERROR lines from eopt-serverless-prod in the last 24 hours (full output)."

  tasks {
    task {
      name        = "count_errors"
      description = "Total ERROR lines in the last 24 hours"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = "${replace(local.eopt_base, "fetch logs", "fetch logs, from:now()-24h")}| summarize total = count()"
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "list_errors"
      description = "Latest 100 ERROR lines, all fields"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = "${replace(local.eopt_base, "fetch logs", "fetch logs, from:now()-24h")}| sort timestamp desc\n| limit 100"
      })
      position {
        x = 1
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the daily digest"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "aij_jp_dl_etool_maintenance@axa.co.jp",
          "chungyueh.chiu@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Alert: eopt - AWS Serverless Error"
        content = "{{ result(\"count_errors\").records[0].total }} ERROR line(s) from eopt-serverless-prod in the last 24 hours. Latest 100:\n\n{% for r in result(\"list_errors\").records %}{{ r.timestamp }}  {{ r[\"aws.log_group\"] }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          count_errors = "SUCCESS"
          list_errors  = "SUCCESS"
        }
        custom = "{{ result(\"count_errors\").records[0].total > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "0 10 * * *"
      }
    }
  }
}

# ##########################################################################
# SECTION: 12-gov-inquiry-system-alerts-tf-check/12-gov-inquiry-system-alerts-tf-check-main.tf
# ##########################################################################

# gov-inquiry-system alerts, converted from dynatrace_log_alert
# 6 are business notices (file summaries, error files received) → scheduled email workflows, no problem
# 1 is a real failure (General Error) → anomaly detector + email workflow

locals {
  gov_email = ["aij_jp_dl_maintenance_operation_-_digitalservices@axa.co.jp"]
  gov_lg    = "/aws/lambda/gov-inquiry-system-prod"

  # Every notice query ends with a single "line" field so the email can print one row per log line
  gov_notices = {
    nd_file_detailed_summary = {
      title   = "[gov-inquiry-system] ND file detailed summary"
      subject = "[Gov Inquiry System] ND file detailed summary"
      query   = <<-EOT
        fetch logs, from:now()-6m, to:now()-1m
        | filter aws.log_group == "/aws/lambda/gov-inquiry-system-prod-parseNdAndUpdateDb"
        | filter contains(content, "Biz file summary", caseSensitive: false)
        | filter contains(content, "fileCategory:ND_SEARCH_RESULT_FILE", caseSensitive: false)
        | parse content, "LD 'fileName:' SPACE? NSPACE:fileName"
        | parse content, "LD 'searchResultCount:' SPACE? INT:searchResultCount"
        | parse content, "LD 'noContractCount:' SPACE? INT:noContractCount"
        | parse content, "LD 'contractExistsCount:' SPACE? INT:contractExistsCount"
        | fieldsAdd line = concat(toString(timestamp), "  ", coalesce(fileName, "-"),
            "  searchResultCount=", coalesce(toString(searchResultCount), "-"),
            "  noContractCount=", coalesce(toString(noContractCount), "-"),
            "  contractExistsCount=", coalesce(toString(contractExistsCount), "-"))
        | fields timestamp, line
        | sort timestamp desc
        | limit 100
      EOT
    }
    answer_file_detailed_summary = {
      title   = "[gov-inquiry-system] answer file detailed summary"
      subject = "[Gov Inquiry System] answer file detailed summary"
      query   = <<-EOT
        fetch logs, from:now()-6m, to:now()-1m
        | filter aws.log_group == "/aws/lambda/gov-inquiry-system-prod-buildAnswerFile"
        | filter contains(content, "Biz file summary", caseSensitive: false)
        | filter contains(content, "fileCategory:ANSWER_FILE", caseSensitive: false)
        | parse content, "LD 'fileName:' SPACE? NSPACE:fileName"
        | parse content, "LD 'requestingGovernmentCount:' SPACE? INT:requestingGovernmentCount"
        | parse content, "LD 'answerCount:' SPACE? INT:answerCount"
        | parse content, "LD 'noMatchCount:' SPACE? INT:noMatchCount"
        | parse content, "LD 'contractExistsCount:' SPACE? INT:contractExistsCount"
        | parse content, "LD 'electronicAnswerUnavailableCount:' SPACE? INT:electronicAnswerUnavailableCount"
        | fieldsAdd line = concat(toString(timestamp), "  ", coalesce(fileName, "-"),
            "  requestingGovernmentCount=", coalesce(toString(requestingGovernmentCount), "-"),
            "  answerCount=", coalesce(toString(answerCount), "-"),
            "  noMatchCount=", coalesce(toString(noMatchCount), "-"),
            "  contractExistsCount=", coalesce(toString(contractExistsCount), "-"),
            "  electronicAnswerUnavailableCount=", coalesce(toString(electronicAnswerUnavailableCount), "-"))
        | fields timestamp, line
        | sort timestamp desc
        | limit 100
      EOT
    }
    request_file_detailed_summary = {
      title   = "[gov-inquiry-system] request file detailed summary"
      subject = "[Gov Inquiry System] request file detailed summary"
      query   = <<-EOT
        fetch logs, from:now()-6m, to:now()-1m
        | filter aws.log_group == "/aws/lambda/gov-inquiry-system-prod-validateAndComputeAnswer"
        | filter contains(content, "Biz file summary", caseSensitive: false)
        | filter contains(content, "fileCategory:REQUEST_FILE", caseSensitive: false)
        | parse content, "LD 'fileName:' SPACE? NSPACE:fileName"
        | parse content, "LD 'requestingGovernmentCount:' SPACE? INT:requestingGovernmentCount"
        | parse content, "LD 'contractRequestCount:' SPACE? INT:contractRequestCount"
        | parse content, "LD 'precheckResultCount:' SPACE? INT:precheckResultCount"
        | fieldsAdd line = concat(toString(timestamp), "  ", coalesce(fileName, "-"),
            "  requestingGovernmentCount=", coalesce(toString(requestingGovernmentCount), "-"),
            "  contractRequestCount=", coalesce(toString(contractRequestCount), "-"),
            "  precheckResultCount=", coalesce(toString(precheckResultCount), "-"))
        | fields timestamp, line
        | sort timestamp desc
        | limit 100
      EOT
    }
    error_file_processing = {
      title   = "gov-inquiry-system Error File Processing"
      subject = "gov-inquiry-system: error file processing"
      query   = <<-EOT
        fetch logs, from:now()-6m, to:now()-1m
        | filter aws.log_group == "/aws/lambda/gov-inquiry-system-prod-parseErrorFileAndUpdateDb"
        | filter contains(content, "ParseErrorFileAndUpdateDB", caseSensitive: false)
        | fieldsAdd line = concat(toString(timestamp), "  ", content)
        | fields timestamp, line
        | sort timestamp desc
        | limit 100
      EOT
    }
    system_error_file_processing = {
      title   = "gov-inquiry-system System Error File Processing"
      subject = "gov-inquiry-system: system error file"
      query   = <<-EOT
        fetch logs, from:now()-6m, to:now()-1m
        | filter aws.log_group == "/aws/lambda/gov-inquiry-system-prod-parseSysErrorFileAndUpdateDb"
        | filter contains(content, "parseGatewaySysErrorFileAndUpdateDbEffect", caseSensitive: false)
        | fieldsAdd line = concat(toString(timestamp), "  ", content)
        | fields timestamp, line
        | sort timestamp desc
        | limit 100
      EOT
    }
    mdm_file_summary = {
      title   = "[gov-inquiry-system] MDM file summary"
      subject = "[Gov Inquiry System] MDM file summary"
      query   = <<-EOT
        fetch logs, from:now()-6m, to:now()-1m
        | filter aws.log_group == "/aws/lambda/gov-inquiry-system-prod-parseMdmResponseAndUpdateDb"
        | filter contains(content, "Biz file summary", caseSensitive: false)
        | fieldsAdd line = concat(toString(timestamp), "  ", content)
        | fields timestamp, line
        | sort timestamp desc
        | limit 100
      EOT
    }
  }
}

# ALERTS 1, 2, 3, 5, 6, 7: business notices every 5 minutes, email only when lines were found
resource "dynatrace_automation_workflow" "gov_notice" {
  for_each = local.gov_notices

  title       = each.value.title
  description = "Every 5 minutes: email matching gov-inquiry-system log lines. Notice only, no problem is opened."

  tasks {
    task {
      name        = "find_lines"
      description = "Matching lines in the last 5 minutes (shifted 1 minute for ingest delay)"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = each.value.query
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email digitalservices maintenance"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = local.gov_email
        cc      = []
        bcc     = []
        subject = each.value.subject
        content = "{{ result(\"find_lines\").records | length }} line(s) in the last 5 minutes.\n\n{% for r in result(\"find_lines\").records %}{{ r.line }}\n{% endfor %}"
      })
      conditions {
        states = {
          find_lines = "SUCCESS"
        }
        custom = "{{ result(\"find_lines\").records | length > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "*/5 * * * *"
      }
    }
  }
}

# ALERT 4: General Error (real failure)
resource "dynatrace_davis_anomaly_detectors" "gov_inquiry_general_error" {
  title       = "gov-inquiry-system General Error"
  description = "A General Error occurred in the gov-inquiry-system (logFailure Lambda logged level:ERROR)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/gov-inquiry-system-prod-logFailure"
          | filter contains(content, "level:ERROR", caseSensitive: false)
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "gov-inquiry-system General Error"
      }
      property {
        key   = "event.description"
        value = "A General Error occurred in the gov-inquiry-system."
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "gov_inquiry_general_error_email" {
  title       = "gov-inquiry-system General Error - email"
  description = "When the General Error problem opens, email the recent level:ERROR lines."

  tasks {
    task {
      name        = "recent_errors"
      description = "level:ERROR lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          | filter aws.log_group == "/aws/lambda/gov-inquiry-system-prod-logFailure"
          | filter contains(content, "level:ERROR", caseSensitive: false)
          | fields timestamp, content
          | sort timestamp desc
          | limit 100
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email digitalservices maintenance"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = local.gov_email
        cc      = []
        bcc     = []
        subject = "gov-inquiry-system: General Error"
        content = "Problem {{ event()[\"display_id\"] }}: General Error in gov-inquiry-system\n\n{% for r in result(\"recent_errors\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_errors = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "matchesPhrase(event.name, \"gov-inquiry-system General Error\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 13-hpm-sharepoint-api-alert-tf-check/13-hpm-sharepoint-api-alert-tf-check-main.tf
# ##########################################################################

# ALERT: Prod_Life_HPM_SharepointAPILambdaError_Normal
# Daily 10:00 JST digest of ERROR lines from hpm-sharepoint-api-prod (S3 <-> SharePoint transfers)

locals {
  hpm_sp_errors = <<-EOT
    | filter aws.log_group == "/aws/lambda/hpm-sharepoint-api-prod"
    | filter status == "ERROR" or contains(content, "ERROR", caseSensitive: false)
  EOT
}

resource "dynatrace_automation_workflow" "hpm_sharepoint_api_lambda_error" {
  title       = "Prod_Life_HPM_SharepointAPILambdaError_Normal"
  description = "To check Lambda error: failure transferring files from S3 to SharePoint and SharePoint to S3. Daily 10:00 JST digest of the last 24 hours."

  tasks {
    task {
      name        = "count_errors"
      description = "Total ERROR lines in the last 24 hours"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = "fetch logs, from:now()-24h\n${local.hpm_sp_errors}| summarize total = count()"
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "list_errors"
      description = "Latest 100 ERROR lines"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = "fetch logs, from:now()-24h\n${local.hpm_sp_errors}| fields timestamp, status, content\n| sort timestamp desc\n| limit 100"
      })
      position {
        x = 1
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the HPM team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "naoya.sota@axa.co.jp",
          "chungyueh.chiu@axa.co.jp",
          "hiroshi.annaka@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Prod_Life_HPM_SharepointAPILambdaError_Normal"
        content = "{{ result(\"count_errors\").records[0].total }} ERROR line(s) from hpm-sharepoint-api-prod in the last 24 hours. Latest 100:\n\n{% for r in result(\"list_errors\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          count_errors = "SUCCESS"
          list_errors  = "SUCCESS"
        }
        custom = "{{ result(\"count_errors\").records[0].total > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "0 10 * * *"
      }
    }
  }
}

# ##########################################################################
# SECTION: 14-hpm-survey-monkey-alert-tf-check/14-hpm-survey-monkey-alert-tf-check-main.tf
# ##########################################################################

# ALERT: Prod_Life_HPM_SurveyMonkeyLambdaError_Normal
# Lambda hpm-survey-monkey-prod logged an error while transferring files from SurveyMonkey to S3

resource "dynatrace_davis_anomaly_detectors" "hpm_survey_monkey_lambda_error" {
  title       = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal"
  description = "To check Lambda error: failure transferring files from SurveyMonkey to S3 (hpm-survey-monkey-prod)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/hpm-survey-monkey-prod"
          | filter status == "ERROR" or contains(content, "ERROR", caseSensitive: false)
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "60"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal"
      }
      property {
        key   = "event.description"
        value = "Lambda /aws/lambda/hpm-survey-monkey-prod logged an error. Failure transferring files from SurveyMonkey to S3."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "hpm_survey_monkey_lambda_error_email" {
  title       = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal - email"
  description = "When the problem opens, email the recent ERROR lines to the HPM team. No PagerDuty (Normal)."

  tasks {
    task {
      name        = "recent_errors"
      description = "ERROR lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          | filter aws.log_group == "/aws/lambda/hpm-survey-monkey-prod"
          | filter status == "ERROR" or contains(content, "ERROR", caseSensitive: false)
          | fields timestamp, status, content
          | sort timestamp desc
          | limit 100
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the HPM team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "naoya.sota@axa.co.jp",
          "chungyueh.chiu@axa.co.jp",
          "hiroshi.annaka@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal"
        content = "Problem {{ event()[\"display_id\"] }}: error in hpm-survey-monkey-prod (SurveyMonkey to S3)\n\n{% for r in result(\"recent_errors\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_errors = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "matchesPhrase(event.name, \"Prod_Life_HPM_SurveyMonkeyLambdaError_Normal\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 15-bre-innorules-alert-tf-check/15-bre-innorules-alert-tf-check-main.tf
# ##########################################################################

# ALERT: BRE alert (InnoRules Lambda logs a line with log level ERROR)
# Converted from dynatrace_log_alert. Pages PagerDuty.

variable "bre_pagerduty_routing_key" {
  description = "PagerDuty Events v2 routing key for the BRE service. Pass from a CI secret, never commit."
  type        = string
  sensitive   = true
}

resource "dynatrace_davis_anomaly_detectors" "bre_alert_innorules" {
  title       = "Prod_Life_BRE_InnoRulesError"
  description = "Alert when logs from innorules-prod contain log level ERROR."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/innorules-prod"
          | filter contains(content, "ERROR")
          | parse content, "LD SPACE LD SPACE WORD:loglevel"
          | filter loglevel == "ERROR"
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_Life_BRE_InnoRulesError"
      }
      property {
        key   = "event.description"
        value = "BRE alert: InnoRules ERROR detected in /aws/lambda/innorules-prod."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "bre_innorules_pagerduty" {
  title       = "Prod_Life_BRE_InnoRulesError - PagerDuty"
  description = "Sends the BRE InnoRules problem to the BRE PagerDuty service."

  tasks {
    task {
      name        = "pagerduty_trigger"
      description = "PagerDuty Events v2 trigger for the BRE service"
      action      = "dynatrace.automations:http-function"
      active      = true
      input = jsonencode({
        method = "POST"
        url    = "https://events.pagerduty.com/v2/enqueue"
        headers = {
          "Content-Type" = "application/json"
        }
        payload = jsonencode({
          routing_key  = var.bre_pagerduty_routing_key
          event_action = "trigger"
          dedup_key    = "dt-problem-{{ event()[\"display_id\"] }}"
          payload = {
            summary  = "BRE alert: InnoRules ERROR detected"
            source   = "innorules-prod"
            severity = "error"
            custom_details = {
              problem_id = "{{ event()[\"display_id\"] }}"
            }
          }
        })
      })
      position {
        x = 0
        y = 1
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "matchesPhrase(event.name, \"Prod_Life_BRE_InnoRulesError\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 16-emma-msgbox-alert-tf-check/16-emma-msgbox-alert-tf-check-main.tf
# ##########################################################################

# ALERT: Prod_Life_Emma_OverallMsgBoxErrors_Normal
# More than 5 error or warn lines from message-box-api-prod within 5 minutes

locals {
  emma_msgbox_filter = <<-EOT
    | filter aws.log_group == "/aws/lambda/message-box-api-prod"
    | filter contains(content, "error", caseSensitive: false) or contains(content, "warn", caseSensitive: false)
  EOT
}

resource "dynatrace_davis_anomaly_detectors" "emma_overall_msgbox_errors" {
  title       = "Prod_Life_Emma_OverallMsgBoxErrors_Normal"
  description = "Catch unexpected errors related to Emma Life MsgBox: more than 5 error or warn lines in 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          ${local.emma_msgbox_filter}
          | makeTimeseries count = count(default: 0), interval:1m
          | fieldsAdd count = arrayMovingSum(count, 5)
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "5"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_Life_Emma_OverallMsgBoxErrors_Normal"
      }
      property {
        key   = "event.description"
        value = "More than 5 error or warn lines from /aws/lambda/message-box-api-prod within 5 minutes."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "emma_overall_msgbox_errors_email" {
  title       = "Prod_Life_Emma_OverallMsgBoxErrors_Normal - email"
  description = "When the problem opens, email the recent error and warn lines. No PagerDuty (Normal)."

  tasks {
    task {
      name        = "recent_errors"
      description = "Error and warn lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          ${local.emma_msgbox_filter}
          | fields timestamp, status, content
          | sort timestamp desc
          | limit 100
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the Emma Teams channel and owners"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "e33bdf34.axa365.onmicrosoft.com@emea.teams.ms",
          "gregoire.homassel@axa.co.jp",
          "axa_jp_dl_bam@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Prod_Life_Emma_OverallMsgBoxErrors_Normal"
        content = "Problem {{ event()[\"display_id\"] }}: more than 5 error or warn lines in message-box-api-prod\n\n{% for r in result(\"recent_errors\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_errors = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "matchesPhrase(event.name, \"Prod_Life_Emma_OverallMsgBoxErrors_Normal\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 17-emma-onboarding-batch-alerts-tf-check/17-emma-onboarding-batch-alerts-tf-check-main.tf
# ##########################################################################

# myaxa-onboarding-batch-prod: 5 error alerts, converted from dynatrace_log_alert
# One detector per alert (for_each) and one shared email workflow.

locals {
  onboarding_log_group = "/aws/lambda/myaxa-onboarding-batch-prod"
  onboarding_prefix    = "Prod_Life_Emma_myaxa-onboarding-batch"

  onboarding_alerts = {
    send_notifications_error = {
      name        = "sendNotifications_error_High"
      description = "sendNotifications logged an error."
      match       = "contains(content, \"sendNotifications :: error\", caseSensitive: false)"
    }
    handle_onboarded_customers_error = {
      name        = "handleOnboardedCustomers_error_High"
      description = "handleOnboardedCustomers logged an error."
      match       = "contains(content, \"handleOnboardedCustomers\", caseSensitive: false) and contains(content, \"error\", caseSensitive: false)"
    }
    queue_consumer_email_sending_failed = {
      name        = "sendNotificationsQueueConsumer_email_sending_failed_High"
      description = "sendNotificationsQueueConsumer failed to send an email."
      match       = "contains(content, \"sendNotificationsQueueConsumer :: email_sending_failed\", caseSensitive: false)"
    }
    queue_consumer_message_sending_failed = {
      name        = "sendNotificationsQueueConsumer_message_sending_failed_High"
      description = "sendNotificationsQueueConsumer failed to send a message."
      match       = "contains(content, \"sendNotificationsQueueConsumer :: message_sending_failed\", caseSensitive: false)"
    }
    queue_consumer_error = {
      name        = "sendNotificationsQueueConsumer_error_High"
      description = "sendNotificationsQueueConsumer logged an error."
      match       = "contains(content, \"sendNotificationsQueueConsumer :: error\", caseSensitive: false)"
    }
  }

  onboarding_any_match = join(" or ", [for a in local.onboarding_alerts : "(${a.match})"])
}

resource "dynatrace_davis_anomaly_detectors" "onboarding_batch" {
  for_each = local.onboarding_alerts

  title       = "${local.onboarding_prefix}_${each.value.name}"
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "${local.onboarding_log_group}"
          | filter ${each.value.match}
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "${local.onboarding_prefix}_${each.value.name}"
      }
      property {
        key   = "event.description"
        value = "${each.value.description} Log group ${local.onboarding_log_group}."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "onboarding_batch_email" {
  title       = "${local.onboarding_prefix} - email"
  description = "Emails the Emma support team when any myaxa-onboarding-batch problem opens."

  tasks {
    task {
      name        = "recent_errors"
      description = "Matching lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          | filter aws.log_group == "${local.onboarding_log_group}"
          | filter ${local.onboarding_any_match}
          | fields timestamp, content
          | sort timestamp desc
          | limit 100
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the Emma support team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "axa_jp_dl_emma_support@axa.co.jp",
          "shunjin.chen@axa.co.jp",
          "koichi.hasegawa.ose@axa.co.jp",
          "hitoshi.sugiura.ose@axa.co.jp",
          "ahadnoor.shakti@axa.co.jp",
          "julien.tahon@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "[HIGH] Alert: {{ event()[\"event.name\"] }}"
        content = "Problem {{ event()[\"display_id\"] }} opened: {{ event()[\"event.name\"] }}\n\n{% for r in result(\"recent_errors\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_errors = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "startsWith(event.name, \"${local.onboarding_prefix}_\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 18-pmt-api-alerts-tf-check/18-pmt-api-alerts-tf-check-main.tf
# ##########################################################################

# pmt-api-prod: 9 Splunk-style alerts → 8 detectors (alerts 6 and 7 were duplicates)
# plus 3 email workflows, one per recipient group.

locals {
  pmt_log_group = "/aws/lambda/pmt-api-prod"

  # Extracts the number from Lambda REPORT lines: "... Max Memory Used: 312 MB ..."
  pmt_parse = "parse content, \"LD 'Max Memory Used: ' INT:memory_usage\""

  pmt_alerts = {
    unexpected_error = {
      name        = "Prod_Life_PMT_UnexpectedError_Normal"
      description = "pmt-api logged 'Unexpected error'."
      match       = "contains(content, \"Unexpected error\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "pa"
    }
    memory_usage_high = {
      name        = "Prod_Life_PMT_STPAPIsMemoryUsageOver480MB_Normal"
      description = "pmt-api Lambda used more than 480 MB of memory in one invocation."
      match       = "isNotNull(memory_usage)"
      series      = "memory_mb = max(memory_usage)"
      threshold   = "480"
      group       = "pa_koichi"
    }
    transformation_timeout = {
      name        = "Prod_Life_PMT_TransformationTimeout_Normal"
      description = "pmt-api Lambda hit its timeout ('Task timed out')."
      match       = "contains(content, \"Task timed out\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "pa"
    }
    send_approval_reminder_failed = {
      name        = "Prod_Life_PMT_SendApprovalReminderHandlerFailed_Normal"
      description = "SendApprovalReminder handler failed."
      match       = "contains(content, \"SendApprovalReminder handler failed\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "pa"
    }
    sfdc_error = {
      name        = "Prod_Life_PMT_SFDCError_Normal"
      description = "An error occurred while calling the SFDC (Salesforce) API."
      match       = "contains(content, \"An error occurred while calling sfdc api\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "adept"
    }
    exception_myaxa_mail_sender = {
      name        = "Prod_Life_Emma_ExceptionInMyAxaMailSender_Normal"
      description = "This alert is used for detecting the exception in MyAxa Mail sender."
      match       = "contains(content, \"Exception in myAxaMailSender\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "none"
    }
    exception_export_data = {
      name        = "Prod_Life_PMT_ExceptionInExportDataForDatalake_Normal"
      description = "Exception in ExportData for Datalake."
      match       = "contains(content, \"Exception in ExportData\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "pa_koichi"
    }
    email_sending_error = {
      name        = "Prod_Life_PMT_EmailSendingProcessError_Normal"
      description = "Error occurred during email sending process for a user."
      match       = "contains(content, \"Error occurred during email sending process for this user\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "pa"
    }
  }

  pmt_email_groups = {
    pa = {
      to      = ["alj_jp_dl_processautomation@axa.co.jp"]
      subject = "Alert: {{ event()[\"event.name\"] }}"
    }
    pa_koichi = {
      to      = ["koichi.nagamine@axa.co.jp", "alj_jp_dl_processautomation@axa.co.jp"]
      subject = "Alert: {{ event()[\"event.name\"] }}"
    }
    adept = {
      to      = ["ALJ_JP_DL_adept@axa.co.jp"]
      subject = "[pmt-api] SFDC処理失敗のお知らせ"
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "pmt_api" {
  for_each = local.pmt_alerts

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "${local.pmt_log_group}"
          | ${local.pmt_parse}
          | filter ${each.value.match}
          | makeTimeseries ${each.value.series}, interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = each.value.threshold
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = each.value.name
      }
      property {
        key   = "event.description"
        value = "${each.value.description} Log group ${local.pmt_log_group}."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "pmt_api_email" {
  for_each = local.pmt_email_groups

  title       = "pmt-api alerts - email (${each.key})"
  description = "Emails recipient group ${each.key} when one of its pmt-api problems opens."

  tasks {
    task {
      name        = "recent_lines"
      description = "Matching lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          | filter aws.log_group == "${local.pmt_log_group}"
          | ${local.pmt_parse}
          | filter ${join(" or ", [for a in local.pmt_alerts : "(${a.match == "isNotNull(memory_usage)" ? "memory_usage > 480" : a.match})" if a.group == each.key])}
          | fields timestamp, content
          | sort timestamp desc
          | limit 50
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email recipient group ${each.key}"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = each.value.to
        cc      = []
        bcc     = []
        subject = each.value.subject
        content = "Problem {{ event()[\"display_id\"] }} opened: {{ event()[\"event.name\"] }}\n\n{% for r in result(\"recent_lines\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_lines = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = join(" or ", [for a in local.pmt_alerts : "matchesPhrase(event.name, \"${a.name}\")" if a.group == each.key])
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 19-recruitimp-serverless-alerts-tf-check/19-recruitimp-serverless-alerts-tf-check-main.tf
# ##########################################################################

# recruitimp-serverless-prod: 2 alerts converted from dynatrace_log_alert
# Alert 1 (daily 08:00 digest)  → scheduled workflow
# Alert 2 (every 5 min)         → detector + email workflow

locals {
  # Confirm the real name: alert 1 in the original file says "recrutimp" (no i), alert 2 says "recruitimp".
  recruitimp_log_group = "/aws/lambda/recruitimp-serverless-prod"

  # Works for Node.js ("ts<TAB>requestId<TAB>ERROR<TAB>msg") and Python ("[ERROR]<TAB>ts...") Lambda lines.
  recruitimp_error_filter = <<-EOT
    | filter aws.log_group == "${local.recruitimp_log_group}"
    | filter status == "ERROR" or contains(content, "\tERROR\t") or contains(content, "[ERROR]")
  EOT

  recruitimp_ri_filter = <<-EOT
    | filter aws.log_group == "${local.recruitimp_log_group}"
    | parse content, "NSPACE:session_id SPACE WORD:level SPACE NSPACE:user_id"
    | filter level == "ERROR"
  EOT
}

# Alert 1: daily digest of yesterday's errors
resource "dynatrace_automation_workflow" "recruitimp_aws_serverless_error_daily" {
  title       = "Prod_Life_RecruitImp_AWSServerlessError_Daily"
  description = "Every day at 08:00 JST, email the ERROR lines from recruitimp-serverless-prod in the last 24 hours."

  tasks {
    task {
      name        = "count_errors"
      description = "ERROR lines in the last 24 hours"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          ${local.recruitimp_error_filter}
          | summarize total = count()
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "list_errors"
      description = "Latest 100 ERROR lines"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          ${local.recruitimp_error_filter}
          | fields timestamp, content
          | sort timestamp desc
          | limit 100
        EOT
      })
      conditions {
        states = {
          count_errors = "OK"
        }
        custom = "{{ result(\"count_errors\").records[0].total > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
    task {
      name        = "send_email"
      description = "Email the eTool maintenance team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "alj_jp_dl_etool_maintenance@axa.co.jp",
          "chungyueh.chiu@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Alert: Prod_Life_RecruitImp_AWSServerlessError_Daily ({{ result(\"count_errors\").records[0].total }} errors)"
        content = "recruitimp-serverless-prod logged {{ result(\"count_errors\").records[0].total }} ERROR lines in the last 24 hours. Latest 100:\n\n{% for r in result(\"list_errors\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          list_errors = "OK"
        }
      }
      position {
        x = 0
        y = 3
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "0 8 * * *"
      }
    }
  }
}

# Alert 2: RI Monitoring Error
resource "dynatrace_davis_anomaly_detectors" "recruitimp_ri_monitoring_error" {
  title       = "Prod_Life_RecruitImp_RIMonitoringError_Normal"
  description = "RI monitoring logged a line with level ERROR in recruitimp-serverless-prod."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          ${local.recruitimp_ri_filter}
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_Life_RecruitImp_RIMonitoringError_Normal"
      }
      property {
        key   = "event.description"
        value = "RI monitoring logged level ERROR in /aws/lambda/recruitimp-serverless-prod."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "recruitimp_ri_monitoring_error_email" {
  title       = "Prod_Life_RecruitImp_RIMonitoringError_Normal - email"
  description = "When the RI monitoring problem opens, email the recent error lines."

  tasks {
    task {
      name        = "recent_errors"
      description = "RI ERROR lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          ${local.recruitimp_ri_filter}
          | fields timestamp, session_id, user_id, content
          | sort timestamp desc
          | limit 50
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the eTool maintenance team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["alj_jp_dl_etool_maintenance@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Alert: {{ event()[\"event.name\"] }}"
        content = "Problem {{ event()[\"display_id\"] }} opened.\n\n{% for r in result(\"recent_errors\").records %}{{ r.timestamp }}  session={{ r.session_id }}  user={{ r.user_id }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_errors = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "matchesPhrase(event.name, \"Prod_Life_RecruitImp_RIMonitoringError_Normal\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 20-sa-support-batches-alerts-tf-check/20-sa-support-batches-alerts-tf-check-main.tf
# ##########################################################################

# sa-support-batches-prod: 3 alerts converted from dynatrace_log_alert
# Alerts 1 and 3 (error, timeout, every 5 min) → 2 detectors (for_each) + 1 email workflow
# Alert 2 (weekday 08:30 "did the import run?")  → scheduled workflow, emails when fewer than 2 lines

locals {
  sa_log_group = "/aws/lambda/sa-support-batches-prod"
  sa_prefix    = "Prod_Life_SA_SupportBatch"

  sa_alerts = {
    batch_error = {
      name        = "${local.sa_prefix}_Error_Normal"
      description = "sa-support-batches logged an error."
      match       = "contains(content, \"error\", caseSensitive: false)"
    }
    task_timeout = {
      name        = "${local.sa_prefix}_TaskTimeOut_Normal"
      description = "sa-support-batches Lambda hit its timeout ('Task timed out')."
      match       = "contains(content, \"Task timed out\", caseSensitive: false)"
    }
  }

  # Confirm against real lines (check.dql query 2). The original used OR with "started",
  # which matches almost anything and hides a missing run.
  sa_import_match = "contains(content, \"importFileHandler :: runner\", caseSensitive: false) and contains(content, \"importSagaFundGroup\", caseSensitive: false)"
}

resource "dynatrace_davis_anomaly_detectors" "sa_support_batch" {
  for_each = local.sa_alerts

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "${local.sa_log_group}"
          | filter ${each.value.match}
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = each.value.name
      }
      property {
        key   = "event.description"
        value = "${each.value.description} Log group ${local.sa_log_group}."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "sa_support_batch_email" {
  title       = "${local.sa_prefix} - email"
  description = "Emails the common-infra team when an sa-support-batches error or timeout problem opens."

  tasks {
    task {
      name        = "recent_lines"
      description = "Error and timeout lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          | filter aws.log_group == "${local.sa_log_group}"
          | filter ${join(" or ", [for a in local.sa_alerts : "(${a.match})"])}
          | fields timestamp, content
          | sort timestamp desc
          | limit 50
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the common-infra team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "alj_jp_dl_bap_commoninfsound2@axa.co.jp",
          "maki.kawauchi.os@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Alert: {{ event()[\"event.name\"] }}"
        content = "Problem {{ event()[\"display_id\"] }} opened: {{ event()[\"event.name\"] }}\n\n{% for r in result(\"recent_lines\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_lines = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "startsWith(event.name, \"${local.sa_prefix}_\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# Alert 2: weekday 08:30 check that the file import ran (at least 2 matching lines in 24 h)
resource "dynatrace_automation_workflow" "sa_support_batch_file_import_confirmation" {
  title       = "${local.sa_prefix}_FileImportConfirmation_Normal"
  description = "Weekdays 08:30 JST: email the annuity payment team if the file import logged fewer than 2 lines in the last 24 hours."

  tasks {
    task {
      name        = "count_import_lines"
      description = "Import lines in the last 24 hours"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          | filter aws.log_group == "${local.sa_log_group}"
          | filter ${local.sa_import_match}
          | summarize total = count(), last_seen = max(timestamp)
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the annuity payment team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["axa_jp_dl_bap_annuitypayment@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Alert: ${local.sa_prefix}_FileImportConfirmation_Normal (import may not have run)"
        content = "sa-support-batches file import logged {{ result(\"count_import_lines\").records[0].total }} matching lines in the last 24 hours (expected at least 2).\nLast seen: {{ result(\"count_import_lines\").records[0].last_seen }}"
      })
      conditions {
        states = {
          count_import_lines = "OK"
        }
        custom = "{{ result(\"count_import_lines\").records[0].total < 2 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "30 8 * * 1-5"
      }
    }
  }
}

# ##########################################################################
# SECTION: 22-terraform-variables-inside-resource/22-terraform-variables-inside-resource-inline.tf
# ##########################################################################

# Option B: no variable or locals blocks. Values are written straight into the resources.
# Use this if the team wants each alert file to be fully self-contained.

resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_failed" {
  title       = "Cisco VPN : LDAP Connections are failing which will impact end users"
  description = "VPN users who log in with Windows credentials cannot connect: Cisco ASA marked the Windows_LDAP server group FAILED more than 3 times in 1 minute."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter matchesValue(dt.system.bucket, "network*")
          | filter contains(content, "Windows_LDAP as FAILED", caseSensitive: false)
          | dedup timestamp, content
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "3"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "1"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Cisco VPN : LDAP Connections are failing which will impact end users"
      }
      property {
        key   = "event.description"
        value = "More than 3 'Windows_LDAP as FAILED' messages from Cisco ASA in 1 minute (ASA-2-113022). VPN users and business users using Windows login are impacted."
      }
      property {
        key   = "alert.severity"
        value = "critical"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "cisco_vpn_ldap_failed_email" {
  title       = "Cisco VPN : LDAP Connections are failing which will impact end users - email"
  description = "Emails the network team with the recent ASA LDAP failure lines. Paging is done by the standard SILVA and PagerDuty workflow."

  tasks {
    task {
      name        = "recent_failures"
      description = "LDAP FAILED lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          | filter matchesValue(dt.system.bucket, "network*")
          | filter contains(content, "Windows_LDAP as FAILED", caseSensitive: false)
          | dedup timestamp, content
          | fields timestamp, log.source, content
          | sort timestamp desc
          | limit 50
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the network team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["<network-team-dl>@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "[CRITICAL] {{ event()[\"event.name\"] }}"
        content = "Problem {{ event()[\"display_id\"] }}: Cisco ASA is marking the Windows_LDAP server group FAILED. VPN logins with Windows credentials are failing.\n\n{% for r in result(\"recent_failures\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_failures = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "matchesPhrase(event.name, \"LDAP Connections are failing\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ##########################################################################
# SECTION: 26-oud-restart-failed-terraform-only/26-oud-restart-failed-terraform-only.tf
# ##########################################################################

# ==========================================
# ALERT: OUD restart failed
# Splunk: index=ods sourcetype=oud_service failed
#         cron 1 4 * * *, last 24 hours, results > 0, High, PagerDuty, email
# ==========================================

resource "dynatrace_davis_anomaly_detectors" "oud_restart_failed" {
  title       = "Prod_OUD_RestartFailed_High"
  description = "The OUD (Oracle Unified Directory) service restart logged 'failed'. Directory lookups and logins that depend on OUD may fail."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*oud_service*")
          | filter matchesPhrase(content, "failed")
          | makeTimeseries count = count(default: 0), by:{ dt.entity.host }, interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_OUD_RestartFailed_High"
      }
      property {
        key   = "event.description"
        value = "OUD service restart failed on {dims:dt.entity.host}. Check the oud_service log on that host."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "dt.source_entity"
        value = "{dims:dt.entity.host}"
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: 27-openpaas-splunk-alerts-transform/27-openpaas-splunk-alerts-transform.tf
# ##########################################################################

# ==========================================
# OpenPaaS / ESG Splunk alerts → Dynatrace detectors (Terraform only, no workflows)
# 7 Splunk alerts → 5 detectors (3 "Emma BE timeout to ESG" alerts had the same search)
#
# CONFIRM BEFORE APPLY: the Splunk index / sourcetype / host filters below are mapped to
# Dynatrace fields by guess. Run check.dql query 1 and replace each line marked CONFIRM.
# ==========================================

locals {
  openpaas_alerts = {

    # Splunk: ALJ OpenPaaS Egress Proxy Public IP Usage Alert
    # index=apigw_syslog sourcetype=apigw_syslog_prod /maam/* (*52.76.125.86* OR *54.179.120.88*)
    # | stats count | where count <= 0   → every 15 min over 15 min, High, email
    # Absence alert: fires when neither egress IP was used for 15 minutes.
    egress_proxy_ip_absent = {
      name        = "Prod_OpenPaaS_EgressProxyPublicIPUsage_High"
      description = "Only one egress proxy public IP is in use: neither 52.76.125.86 nor 54.179.120.88 appeared in ESG (/maam/) logs for 15 minutes."
      severity    = "high"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*apigw_syslog*")
        | filter contains(content, "/maam/")
        | filter contains(content, "52.76.125.86") or contains(content, "54.179.120.88")
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM line 1 (Splunk index=apigw_syslog sourcetype=apigw_syslog_prod)
      threshold   = "1"
      condition   = "BELOW"
      violating   = "15"
      window      = "15"
      dealerting  = "5"
    }

    # Splunk (3 alerts, same search):
    #   ESG - Emma BE timeout to ESG Production                       (email)
    #   Prod_Life_Emma_EmmaBETmeoutToESGProduction_High               (High, PagerDuty, email)
    #   Prod_Life_Emma_EmmaBETmeoutToESGProduction_High_PagerDuty     (PagerDuty)
    # index="myaxabackend-prod-axa-li-jp" "api-jp-cert.corp.intraxa" AND "java.net.SocketTimeoutException"
    # | append [search index="apigw_syslog" sourcetype=apigw_syslog_prod "Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa"]
    # every 5 min over 5 min, results > 20, throttle 60 s
    emma_be_timeout_to_esg = {
      name        = "Prod_Life_Emma_EmmaBETimeoutToESGProduction_High"
      description = "More than 20 timeouts in 5 minutes on calls from Emma BE (OpenPaaS) to ESG (CoreIT)."
      severity    = "high"
      query       = <<-EOT
        fetch logs
        | filter (k8s.namespace.name == "myaxabackend-prod-axa-li-jp"
                  and contains(content, "api-jp-cert.corp.intraxa", caseSensitive: false)
                  and contains(content, "java.net.SocketTimeoutException", caseSensitive: false))
              or (matchesValue(log.source, "*apigw_syslog*")
                  and contains(content, "Problem routing to", caseSensitive: false)
                  and contains(content, "timed out", caseSensitive: false)
                  and contains(content, "myaxa-api.alj.intraxa", caseSensitive: false))
        | makeTimeseries count = count(default: 0), interval:1m
        | fieldsAdd count = arrayMovingSum(count, 5)
      EOT
      # CONFIRM: k8s.namespace.name (Splunk index=myaxabackend-prod-axa-li-jp) and log.source (apigw_syslog)
      threshold   = "20"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: PIS Connection Issue (Batch->OpenPaaS) Alert
    # index=claims host="CEAA2058.prprivmgmt.intraxa" sourcetype=pis_defaultlog
    # | regex _raw="\"errorCode\":\s\"ESG120\""   → every 5 min over 5 min, > 0, email (Normal)
    pis_connection_esg120 = {
      name        = "Prod_Claims_PISConnectionIssueBatchToOpenPaaS_Normal"
      description = "PIS batch on CEAA2058 logged errorCode ESG120 (connection issue from Batch to OpenPaaS)."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(host.name, "ceaa2058*")
        | filter matchesValue(log.source, "*pis_default*")
        | filter contains(content, "errorCode") and contains(content, "\"ESG120\"")
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM: host.name and log.source (Splunk host=CEAA2058.prprivmgmt.intraxa sourcetype=pis_defaultlog)
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: eopt - OpenPaaS Pod Error (Backend)
    # index="eopt-prod-axa-li-jp" | rex "(?<timestamp>ISO8601 ms Z)\s+(?<level>[A-Z]+)" | eval level=upper(level) | search level="ERROR"
    # every hour at :00, > 0, email (Normal)
    eopt_pod_error_backend = {
      name        = "Prod_eopt_OpenPaaSPodErrorBackend_Normal"
      description = "eopt backend pod on OpenPaaS logged a line with level ERROR."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter k8s.namespace.name == "eopt-prod-axa-li-jp"
        | parse content, "LD ISO8601:log_ts SPACE+ WORD:level"
        | filter upper(level) == "ERROR"
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM: k8s.namespace.name (Splunk index=eopt-prod-axa-li-jp) and that the parse matches (check.dql query 3)
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "60"
    }

    # Splunk: eopt - OpenPaaS Pod Error (Frontend)
    # index="eopt-prod-axa-li-jp" | spath | eval level=upper(level) | search level="ERROR"
    # every hour at :00, > 0, email (Normal)
    eopt_pod_error_frontend = {
      name        = "Prod_eopt_OpenPaaSPodErrorFrontend_Normal"
      description = "eopt frontend pod on OpenPaaS logged a JSON line with level ERROR."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter k8s.namespace.name == "eopt-prod-axa-li-jp"
        | parse content, "JSON:j"
        | filter upper(toString(j[level])) == "ERROR"
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM: k8s.namespace.name and that JSON lines have a "level" key (check.dql query 3)
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "60"
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "openpaas" {
  for_each = local.openpaas_alerts

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "threshold"
        value = each.value.threshold
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = each.value.condition
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = each.value.violating
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = each.value.window
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = each.value.dealerting
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = each.value.name
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = each.value.severity
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: 28-powercenter-down-alerts-check/28-powercenter-down-alerts-check.tf
# ##########################################################################

# Replaces 3 Splunk alerts that all run: index="powercenter" ISP_MASTER_ELECT_LOCK
#   0031_MWSP-PowerCenter-Service-Down-Alert  last 1 min,  every 1 min, results > 2, Normal
#   PowerCenter-ProcessStop                   last 15 min, every 1 min, results > 0, High
#   Powercenter down                          last 1 min,  every 1 min, results > 3, Normal
# ProcessStop (> 0) already fires whenever the other two would, so one detector covers all three.

resource "dynatrace_davis_anomaly_detectors" "powercenter_master_elect_lock" {
  title       = "Prod_MWSP_PowerCenter_ServiceDown_High"
  description = "PowerCenter logged ISP_MASTER_ELECT_LOCK. The PowerCenter service or process may be down."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query"
        # CONFIRM line 2: Splunk index="powercenter" → real Dynatrace field (check.dql query 1)
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*powercenter*")
          | filter contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive: false)
          | makeTimeseries count = count(default: 0), by:{ dt.entity.host }, interval:1m
        EOT
      }
      analyzer_input_field {
        # Use "2" instead if check.dql query 2 shows 1-2 lines per minute is normal background
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "15"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_MWSP_PowerCenter_ServiceDown_High"
      }
      property {
        key   = "event.description"
        value = "PowerCenter logged ISP_MASTER_ELECT_LOCK on {dims:dt.entity.host}. The PowerCenter service or process may be down."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "dt.source_entity"
        value = "{dims:dt.entity.host}"
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: 29-datalake-batch-result-transfer/29-datalake-batch-result-transfer.tf
# ##########################################################################

# Replaces Splunk alert "Datalake_Batch Result"
#   index="batch_monitoring_logs" | table _time _raw
#   Time range: Today (midnight to now)   Cron: 0 8 * * *   Fires when results > 0   Email, Normal
# This is a daily report (a table of lines), so it is a scheduled workflow, not a detector.

resource "dynatrace_automation_workflow" "datalake_batch_result" {
  title       = "Prod_Datalake_BatchResult_Normal"
  description = "Daily 08:00 JST: email every batch_monitoring_logs line written since midnight JST."

  tasks {
    task {
      name        = "get_batch_lines"
      description = "Batch monitoring lines since midnight JST"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        # Runs at 08:00 JST, so now()-8h is midnight JST (same as Splunk "Today")
        # CONFIRM line 3: Splunk index="batch_monitoring_logs" → real Dynatrace field (check.dql query 1)
        query = <<-EOT
          fetch logs, from:now()-8h
          | filter matchesValue(log.source, "*batch_monitoring*")
          | sort timestamp asc
          | fields timestamp, content
          | limit 500
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the batch result list"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        # CONFIRM the address spelling from the Splunk screenshot
        to      = ["masayuki.yasuda@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Prod_Datalake_BatchResult_Normal: {{ result(\"get_batch_lines\").records | length }} lines since midnight"
        content = "Datalake batch monitoring lines since 00:00 JST:\n\n{% for r in result(\"get_batch_lines\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          get_batch_lines = "OK"
        }
        custom = "{{ result(\"get_batch_lines\").records | length > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "0 8 * * *"
      }
    }
  }
}

# ##########################################################################
# SECTION: 31-controlm-alerts-full-inventory-v2/31-controlm-alerts-full-inventory-v2.tf
# ##########################################################################

# Control-M Splunk alerts → Dynatrace, v2 (13 Splunk alerts → 1 detector + 6 workflows)
#
#   Splunk alert                                        Dynatrace
#   CH:UL Email Job status                              daily_reports["chde010m_ul_today"]
#   CHDE010MJob Status for MyAXA UL Email   (30 11 1-6) daily_reports["chde010m_myaxa_ul"] (merged)
#   Job Status for MyAXA UL Email           (30 11 2-6) daily_reports["chde010m_myaxa_ul"] (merged)
#   CHDR010MJob Status for MyAXA User Registration...   daily_reports["chdr010m_user_registration"]
#   Claims Status Service PDDW0100 Status               daily_reports["pddw0100_claims_status"]
#   CTL-M アベンドアラート + CTL-M アベンドアラートV2     controlm_job_abend (detector, merged)
#   CTL-M:ジョブ実行結果通知                              controlm_job_result_notify
#   Claim Job Over Run Alert                             claims_job_overrun
#
# Not migrated:
#   CTL-M:リラン確認                       only action is "Output results to lookup" (ControlmRerunHistory.csv), no notification
#   Claims Status Service PDDW0100 Status_test   test copy (koichi.hasegawa, subject 【test】)
#   Claims Status Service PDDW0100 Status複製    personal copy (shunjin.chen)
#   Job Status for MyAXA UL Email複製            personal copy (shunjin.chen, 25 11 * * 1-6)
#
# CONFIRM before apply:
#   1. log.source values for sourcetype controlm_activejobs and controlm_alert (check.dql query 1)
#   2. Control-M fields (job_name, status, start_time, end_time, order_id, isn, odate, message,
#      application, run_counter, data_center, group_name, owner) exist as log attributes (check.dql query 2).
#      If they only exist inside content, add a parse step after the source filter.
#   3. Lookup files uploaded to Grail (Settings > Lookup data), keyed by job_name:
#        /lookups/controlm/addresslist        (controlm_addresslist.csv, column Method / 対応方法)
#        /lookups/controlm/job_definition     (controlm_job_Definition.csv)
#        /lookups/controlm/specific_contact   (controlm_SpecificContact.csv, column Email)
#        /lookups/controlm/claims_jobs        (claims_jobs.csv)
#        /lookups/controlm/claims_job_list    (claims_job_list.csv, column job_name_jp)
#   4. Every email address (screenshots are blurry; some are cut off)

locals {
  cm_activejobs = "matchesValue(log.source, \"*controlm_activejobs*\")"
  cm_alert      = "matchesValue(log.source, \"*controlm_alert*\")"

  # Control-M times are text like 20261005063015 (yyyyMMddHHmmss, JST)
  cm_start_fmt = "concat(substring(start_time, from:0, to:4), \"/\", substring(start_time, from:4, to:6), \"/\", substring(start_time, from:6, to:8), \" \", substring(start_time, from:8, to:10), \":\", substring(start_time, from:10, to:12), \":\", substring(start_time, from:12, to:14))"
  cm_end_fmt   = "concat(substring(end_time, from:0, to:4), \"/\", substring(end_time, from:4, to:6), \"/\", substring(end_time, from:6, to:8), \" \", substring(end_time, from:8, to:10), \":\", substring(end_time, from:10, to:12), \":\", substring(end_time, from:12, to:14))"

  daily_reports = {

    # Splunk: CH:UL Email Job status   Today, 0 13 * * 2-6, throttle on JOB_CODE (no effect for a daily run)
    chde010m_ul_today = {
      title = "Prod_UL_CHDE010M_JobStatusToday_Normal"
      cron  = "0 13 * * 2-6"
      to    = ["mitsuru.noda@axa.co.jp", "masayuki.yasuda@axa.co.jp"] # CONFIRM, third address is cut off
      cc    = []
      query = <<-EOT
        fetch logs, from:now()-13h
        | filter ${local.cm_activejobs}
        | filter job_name == "CHDE010M"
        | sort timestamp desc
        | dedup order_id
        | fieldsAdd StartTime = ${local.cm_start_fmt}, EndTime = ${local.cm_end_fmt}
        | fields job_name, status, StartTime, EndTime, odate
      EOT
      line  = "{{ r.job_name }}  {{ r.status }}  start {{ r.StartTime }}  end {{ r.EndTime }}  odate {{ r.odate }}"
    }

    # Splunk (2 alerts, same job, same list, same 11:30):
    #   CHDE010MJob Status for MyAXA UL Email   30 11 * * 1-6, dedup odate, only yesterday's order date
    #   Job Status for MyAXA UL Email           30 11 * * 2-6, dedup job_name, CC ops guild + tadashi.yoshida,
    #                                           subject "$name$ $result.MSG$", body "The job status of CHDE010M ..."
    #   Merged: yesterday's-order-date logic (stricter), union of recipients, MSG in the subject.
    chde010m_myaxa_ul = {
      title = "Prod_MyAXA_UL_CHDE010M_JobStatus_Normal"
      cron  = "30 11 * * 1-6"
      to    = ["digital_marketing_squad@axa.co.jp", "axa_jp_dl_emma_support@axa.co.jp"]               # CONFIRM
      cc    = ["alj_jp_dl_ops_guild_marketing_servicing@axa.co.jp", "tadashi.yoshida@axa.co.jp"] # CONFIRM
      query = <<-EOT
        fetch logs, from:now()-1d
        | filter ${local.cm_activejobs}
        | filter job_name == "CHDE010M"
        | sort timestamp desc
        | dedup odate
        | filter odate == formatTimestamp(now() - 1d, format:"yyyyMMdd", timezone:"Asia/Tokyo")
        | fieldsAdd StartTime = ${local.cm_start_fmt}, EndTime = ${local.cm_end_fmt}
        | fieldsAdd MSG = if(status == "Ended OK", "OK", else:"正常終了していません要確認")
        | fields job_name, status, StartTime, EndTime, odate, MSG
      EOT
      line  = "JOB NAME: {{ r.job_name }}\nJOB STATUS: {{ r.status }}\nJOB START: {{ r.StartTime }}\nJOB END: {{ r.EndTime }}\nORDER DATE: {{ r.odate }}\n{{ r.MSG }}\n"
    }

    # Splunk: CHDR010MJob Status for MyAXA User Registration Batch   every day 06:00
    chdr010m_user_registration = {
      title = "Prod_MyAXA_UserRegistration_CHDR010M_JobStatus_Normal"
      cron  = "0 6 * * *"
      to    = ["digital_marketing_squad@axa.co.jp", "axa_jp_dl_emma_support@axa.co.jp"] # CONFIRM
      cc    = ["shunjin.chen@axa.co.jp"]                                                # CONFIRM, Teams channel address left out on purpose
      query = <<-EOT
        fetch logs, from:now()-24h
        | filter ${local.cm_activejobs}
        | filter job_name == "CHDR010M"
        | sort timestamp desc
        | dedup job_name
        | fieldsAdd StartTime = ${local.cm_start_fmt}, EndTime = ${local.cm_end_fmt}
        | fieldsAdd MSG = if(status == "Ended OK", "OK", else:"NG")
        | fields job_name, status, StartTime, EndTime, MSG
      EOT
      line  = "{{ r.job_name }}  {{ r.status }}  start {{ r.StartTime }}  end {{ r.EndTime }}  {{ r.MSG }}"
    }

    # Splunk: Claims Status Service PDDW0100 Status   Last 24 hours, 15 8 * * *, priority Highest, inline table
    #   Message starts "担当各位 PDDWの完了時刻のレポートを送信致します。"
    pddw0100_claims_status = {
      title = "Prod_Claims_PDDW0100_JobStatus_Normal"
      cron  = "15 8 * * *"
      to    = ["akio.fukuda.ose@axa.co.jp", "ryusuke.tsumura@axa.co.jp"] # CONFIRM
      cc    = ["alj_jp_dl_uog_oo_s@axa.co.jp"]                           # CONFIRM, partly unreadable
      query = <<-EOT
        fetch logs, from:now()-24h
        | filter ${local.cm_activejobs}
        | filter startsWith(job_name, "PDDW")
        | filter not endsWith(job_name, "-S") and not endsWith(job_name, "-F") and job_name != "TEST001"
        | sort timestamp desc
        | dedup odate, order_id
        | filter status == "Ended OK"
        | lookup [ load "/lookups/controlm/claims_job_list" ], sourceField:job_name, lookupField:job_name, prefix:"", fields:{ job_name_jp }
        | fieldsAdd StartDate = concat(substring(start_time, from:0, to:4), "/", substring(start_time, from:4, to:6), "/", substring(start_time, from:6, to:8))
        | fieldsAdd StartTime = concat(substring(start_time, from:8, to:10), ":", substring(start_time, from:10, to:12), ":", substring(start_time, from:12, to:14))
        | fieldsAdd EndTime = concat(substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14))
        | sort start_time desc
        | fields job_name, job_name_jp, StartDate, StartTime, EndTime
      EOT
      line  = "JOB {{ r.job_name }}  処理 {{ r.job_name_jp }}  起動日 {{ r.StartDate }}  {{ r.StartTime }} - {{ r.EndTime }}"
    }
  }

  report_intro = {
    chde010m_ul_today          = "CHDE010M job status today."
    chde010m_myaxa_ul          = "The job status of CHDE010M"
    chdr010m_user_registration = "CHDR010M (emma registration batch) job status."
    pddw0100_claims_status     = "担当各位\n\nPDDWの完了時刻のレポートを送信致します。"
  }
}

resource "dynatrace_automation_workflow" "controlm_daily_report" {
  for_each = local.daily_reports

  title       = each.value.title
  description = "Daily Control-M job status email (converted from Splunk)."

  tasks {
    task {
      name        = "get_rows"
      description = "Control-M job status rows"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = each.value.query
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the job status"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = each.value.to
        cc      = each.value.cc
        bcc     = []
        subject = "${each.value.title} {{ result(\"get_rows\").records[0].MSG | default(\"\") }}"
        content = "${local.report_intro[each.key]}\n\n{% for r in result(\"get_rows\").records %}${each.value.line}\n{% endfor %}"
      })
      conditions {
        states = {
          get_rows = "OK"
        }
        custom = "{{ result(\"get_rows\").records | length > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = each.value.cron
      }
    }
  }
}

# Splunk: CTL-M アベンドアラート (V1) and CTL-M アベンドアラートV2
#   sourcetype=controlm_alert message="Ended not OK", last 5 min every minute, throttle JOB_CODE
#   Both alerts run the same base search → one detector, one problem per job_name
resource "dynatrace_davis_anomaly_detectors" "controlm_job_abend" {
  title       = "Prod_ControlM_JobAbend_High"
  description = "A Control-M job ended not OK."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter ${local.cm_alert}
          | filter lower(message) == "ended not ok"
          | makeTimeseries count = count(default: 0), by:{ job_name }, interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "10"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_ControlM_JobAbend_High"
      }
      property {
        key   = "event.description"
        value = "Control-M job {dims:job_name} ended not OK."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
    }
  }

  execution_settings {}
}

# Splunk: CTL-M:ジョブ実行結果通知
#   Jobs that abended in the last 24 h and have now ended (OK = recovered, not OK = failed again).
#   One email per job, To fixed person, CC from controlm_SpecificContact.csv.
#   Splunk ran every minute over overlapping windows + 10 min throttle; here each job end is
#   picked up exactly once: the first snapshot showing the end must fall in the last 5-minute slot.
resource "dynatrace_automation_workflow" "controlm_job_result_notify" {
  title       = "Prod_ControlM_JobResultNotify_Normal"
  description = "Every 5 minutes: one email per Control-M job that abended in the last 24 hours and has now ended."

  tasks {
    task {
      name        = "get_job_results"
      description = "Abended jobs that just ended"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-30m
          | filter ${local.cm_activejobs}
          | filter isNotNull(job_name) and job_name != ""
          | filter not endsWith(job_name, "-F") and not endsWith(job_name, "-S")
          | filter status == "Ended OK" or lower(status) == "ended not ok"
          | summarize first_seen = min(timestamp),
                      job_name = takeLast(job_name), status = takeLast(status),
                      application = takeLast(application), group_name = takeLast(group_name),
                      owner = takeLast(owner), odate = takeLast(odate),
                      start_time = takeLast(start_time), end_time = takeLast(end_time),
                      by:{ order_id, isn }
          | filter first_seen >= now() - 6m and first_seen < now() - 1m
          | lookup [ fetch logs, from:now()-24h
                     | filter ${local.cm_alert}
                     | summarize abend_time = max(timestamp), message = takeLast(message),
                                 data_center = takeLast(data_center), run_counter = takeLast(run_counter),
                                 by:{ order_id } ],
                   sourceField:order_id, lookupField:order_id, prefix:"alert."
          | filter isNotNull(alert.message)
          | lookup [ load "/lookups/controlm/addresslist" ], sourceField:job_name, lookupField:job_name, prefix:"", fields:{ Method }
          | lookup [ load "/lookups/controlm/job_definition" ], sourceField:job_name, lookupField:job_name, prefix:"", fields:{ mem_lib, cmd_line, memname, node_id, host }
          | lookup [ load "/lookups/controlm/specific_contact" ], sourceField:job_name, lookupField:job_name, prefix:"", fields:{ Email }
          | fieldsAdd system = if(alert.data_center == "CEAA204D" or alert.data_center == "Server#1", "Open",
                               else: if(alert.data_center == "mainframe#1", "MF#1",
                               else: if(alert.data_center == "mainframe#3", "MF#3", else: "unknown")))
          | fieldsAdd RUN_COUNT = if(application == "NO_APPL", toLong(alert.run_counter) + 1, else: toLong(alert.run_counter))
          | fieldsAdd PrimarySupport = if(application == "NO_APPL", "", else: concat(":", coalesce(Method, "N/A")))
          | fieldsAdd END_HMS = concat(substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14))
          | fieldsAdd CMD_STRING = if(isNull(mem_lib), cmd_line, else: concat(mem_lib, "\\", memname))
          | fieldsAdd TITLE = if(status == "Ended OK",
                                concat(job_name, " (", system, ")正常終了 (", toString(RUN_COUNT), ")[", END_HMS, "]"),
                                else: concat(job_name, " (", system, ")異常終了 (", toString(RUN_COUNT), PrimarySupport, ") [", END_HMS, "]"))
          | fieldsAdd BODY = if(status == "Ended OK",
                               concat(toString(alert.abend_time), "にアベンドした", job_name, "は正常終了しました"),
                               else: concat(job_name, "が", toString(alert.abend_time), "に異常終了しました"))
          | fieldsAdd recipients = if(isNull(Email) or Email == "",
                                     array("tadashi.yoshida@axa.co.jp"),
                                     else: array("tadashi.yoshida@axa.co.jp", Email))
          | fields TITLE, BODY, recipients, job_name, group_name, owner, odate, status, CMD_STRING, node_id, host
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email_per_job"
      description = "One email per job result"
      action      = "dynatrace.email:send-email"
      active      = true
      with_items  = "rec in {{ result(\"get_job_results\").records }}"
      concurrency = "1"
      input = jsonencode({
        # Whole-field expression so the array keeps its type; test once with a real record
        to      = "{{ _.rec.recipients }}"
        cc      = []
        bcc     = []
        subject = "{{ _.rec.TITLE }}"
        content = "{{ _.rec.BODY }}\n\nJob: {{ _.rec.job_name }}\nGroup: {{ _.rec.group_name }}\nOwner: {{ _.rec.owner }}\nOrder date: {{ _.rec.odate }}\nStatus: {{ _.rec.status }}\nCommand: {{ _.rec.CMD_STRING }}\nNode: {{ _.rec.node_id }}  Host: {{ _.rec.host }}"
      })
      conditions {
        states = {
          get_job_results = "OK"
        }
        custom = "{{ result(\"get_job_results\").records | length > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "*/5 * * * *"
      }
    }
  }
}

# Splunk: Claim Job Over Run Alert   index=controlm* + claims_jobs.csv, Last 24 hours, */5, no throttle
#   A claims job whose latest run has no end time and has been running 15+ minutes.
#   Splunk grouped by job_name (misses a new run when yesterday's run has an end time) and
#   compared elapsed with the text "15". Here it groups by run (order_id) and emails once per run:
#   only when the run crosses 15 minutes (between 15 and 20 minutes old, matching the 5-minute schedule).
resource "dynatrace_automation_workflow" "claims_job_overrun" {
  title       = "Prod_Claims_JobOverRun_Normal"
  description = "Every 5 minutes: email when a claims Control-M job has been running for 15 minutes without ending."

  tasks {
    task {
      name        = "get_overruns"
      description = "Claims jobs running 15+ minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          | filter ${local.cm_activejobs}
          | lookup [ load "/lookups/controlm/claims_jobs" ], sourceField:job_name, lookupField:job_name, prefix:"claims."
          | filter isNotNull(claims.job_name)
          | sort timestamp asc
          | summarize first_seen = min(timestamp), job_name = takeLast(job_name),
                      start_time = takeLast(start_time), end_time = takeLast(end_time),
                      by:{ order_id }
          | filter isNull(end_time) or end_time == ""
          | filter first_seen <= now() - 15m and first_seen > now() - 20m
          | fieldsAdd starttime = ${local.cm_start_fmt}
          | fields job_name, starttime, order_id
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the claims incident list"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["all_jp_dl_incident_claims@axa.co.jp"] # CONFIRM, partly unreadable
        cc      = []
        bcc     = []
        subject = "Prod_Claims_JobOverRun: {{ result(\"get_overruns\").records | length }} jobs running 15+ minutes"
        content = "Claims jobs still running after 15 minutes:\n\n{% for r in result(\"get_overruns\").records %}{{ r.job_name }}  started {{ r.starttime }}  order {{ r.order_id }}\n{% endfor %}"
      })
      conditions {
        states = {
          get_overruns = "OK"
        }
        custom = "{{ result(\"get_overruns\").records | length > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "*/5 * * * *"
      }
    }
  }
}

# ##########################################################################
# SECTION: 32-iwfm-splunk-alerts-transform/32-iwfm-splunk-alerts-transform.tf
# ##########################################################################

# IWFM-related Splunk alerts → Dynatrace detectors (3 Splunk alerts → 3 detectors, no workflows)
#
#   EIP - IWFM : EIP006 service Failure Alert      → iwfm_alerts["eip006_service_failure"]
#   [Prod]ALJ-Compass-IWFMReportException発生       → iwfm_alerts["compass_iwfm_report_exception"]
#   IWFM_Errors                                    → iwfm_alerts["iwfm_agent_errors"]
#
# CONFIRM before apply (check.dql query 1 and 2):
#   index=eip1015 sourcetype=eip_mediator_serverlog   → log.source guess "*eip_mediator_serverlog*"
#   index=compass-prod-axa-li-jp                      → k8s.namespace.name guess
#   index=iwfm sourcetype=fmwsagentlog                → log.source guess "*fmwsagentlog*"
#   Status and LOGLEVEL are Splunk field extractions  → may only exist inside content

locals {
  iwfm_alerts = {

    # Splunk: index=eip1015 sourcetype=eip_mediator_serverlog jp-Distributing-Sell-GenerateFormImage-v2-vs* Status=FAILURE
    #   Last 1 minute, every minute, results > 2, High, email alj_jp_dl_infra_mwss
    eip006_service_failure = {
      name        = "Prod_EIP_IWFM_EIP006ServiceFailure_High"
      description = "More than 2 FAILURE results in 1 minute from EIP006 (jp-Distributing-Sell-GenerateFormImage-v2), which depends on the backend IWFM system."
      severity    = "high"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*eip_mediator_serverlog*")
        | filter contains(content, "jp-Distributing-Sell-GenerateFormImage-v2-vs", caseSensitive: false)
        | filter contains(content, "Status=FAILURE", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      threshold   = "2"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: index=compass-prod-axa-li-jp "IWFMReportException"
    #   Last 5 minutes, every 5 minutes, results > 15, Normal, email compass IT member + aog list
    compass_iwfm_report_exception = {
      name        = "Prod_Compass_IWFMReportException_Normal"
      description = "More than 15 IWFMReportException lines in 5 minutes in Compass (prod)."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter k8s.namespace.name == "compass-prod-axa-li-jp"
        | filter contains(content, "IWFMReportException", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
        | fieldsAdd count = arrayMovingSum(count, 5)
      EOT
      threshold   = "15"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: index=iwfm sourcetype=fmwsagentlog earliest=-1h (LOGLEVEL="Caution" OR LOGLEVEL="Fatal")
    #         | transaction host AGENTID maxspan=1s
    #   Every hour at :15, results > 0, throttle 1 hour, Normal, email raju.kolukuluri
    #   transaction only groups lines that arrive within 1 second; "> 0" still means "any line".
    iwfm_agent_errors = {
      name        = "Prod_IWFM_AgentErrors_Normal"
      description = "IWFM agent (fmwsagentlog) logged LOGLEVEL Caution or Fatal."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*fmwsagentlog*")
        | filter contains(content, "LOGLEVEL=\"Caution\"", caseSensitive: false)
              or contains(content, "LOGLEVEL=\"Fatal\"", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "60"
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "iwfm" {
  for_each = local.iwfm_alerts

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "threshold"
        value = each.value.threshold
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = each.value.condition
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = each.value.violating
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = each.value.window
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = each.value.dealerting
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = each.value.name
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = each.value.severity
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: 34-jenkins-app-monitoring-alerts-transform/34-jenkins-app-monitoring-alerts-transform.tf
# ##########################################################################

# Jenkins "Application Monitoring Alert" family → Dynatrace (10 Splunk alerts → 2 detectors)
#
#   Application Monitoring Alert - URL                     → jenkins_url_check_failed
#   Application Monitoring Alert - URL for MyAXA           → jenkins_url_check_failed
#   Application Monitoring Alert - function                → jenkins_functional_check_failed (pager_duty = 0 apps)
#   ... - function for AG Portal      (AG Portal NTTGW)    → jenkins_functional_check_failed
#   ... - function for BancaPotal     (Banca Portal)       → jenkins_functional_check_failed
#   ... - function for Cockpit360     (Cockpit360)         → jenkins_functional_check_failed
#   ... - function for Compass        (Compass)            → jenkins_functional_check_failed
#   ... - function for Compass PB     (Compass AG)         → jenkins_functional_check_failed
#   ... - function for FCR            (FCR)                → jenkins_functional_check_failed
#   ... - function for ICM            (Claims ICM)         → jenkins_functional_check_failed
#
# Splunk pattern in all 10: keep the last 2 results per check (streamstats index<=2),
# alert when both are NG (event=2 and status=NG), send recovery when OK follows NG,
# Alert Status Manager pages PagerDuty per application.
# Dynatrace: one problem per application + check, opens on 2 failed runs with no OK run in the
# look-back window, closes on the first OK run. PagerDuty keys from the screenshots are NOT copied:
# paging goes through the standard flow, using the pager_duty property (0 = do not page).
#
# CONFIRM before apply:
#   1. log.source for jenkins_console "[HTTP Monitor]" lines and for source="jenkins/test"   (check.dql 1)
#   2. HTTP Monitor line format (where the response code sits)                              (check.dql 2)
#   3. jenkins/test JSON keys: job_name, job_result, testsuite.testcase[].testname/status   (check.dql 3)
#   4. Upload the Splunk "configuration" lookup as /lookups/jenkins/configuration
#      (key job_name, columns application, pager_duty)                                       (check.dql 5)
#   5. Macros check_maintenance_window and add_alert_info: ask for their definitions
#   6. "function" (generic) reads index=jenkins_statistics sourcetype json:jenkins:old. Confirm that
#      source is still written; if yes, add it as a second branch of the functional query.

locals {
  jenkins_url_window_min        = 15  # Splunk: Last 15 minutes
  jenkins_functional_window_min = 120 # Splunk: Last 2 hours

  jenkins_detectors = {

    jenkins_url_check_failed = {
      name        = "Prod_Jenkins_AppMonitoring_URLCheckFailed_High"
      description = "Jenkins HTTP Monitor for {dims:application} ({dims:name}) failed twice in a row with no OK result."
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*jenkins*console*")
        | filter contains(content, "[HTTP Monitor]")
        | parse log.source, "LD 'job/' LD:job_path '/' INT '/console'"
        | fieldsAdd name = replaceString(job_path, "%20", " ")
        | parse content, "LD 'status' LD INT:responsecode"
        | fieldsAdd failed = if(responsecode == 200, 0, else: 1)
        | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
        | fieldsAdd application = coalesce(cfg.application, "-"), pager_duty = coalesce(toString(cfg.pager_duty), "1")
        | makeTimeseries fail = sum(failed, default: 0), ok = sum(1 - failed, default: 0), by:{ application, name, pager_duty }, interval:1m
        | fieldsAdd fail_n = arrayMovingSum(fail, ${local.jenkins_url_window_min}), ok_n = arrayMovingSum(ok, ${local.jenkins_url_window_min})
        | fieldsAdd consecutive_ng = if(fail_n[] >= 2 and ok_n[] == 0, 1, else: 0)
        | fieldsKeep timeframe, interval, application, name, pager_duty, consecutive_ng
      EOT
    }

    jenkins_functional_check_failed = {
      name        = "Prod_Jenkins_AppMonitoring_FunctionalCheckFailed_High"
      description = "Jenkins functional test {dims:testname} for {dims:application} failed twice in a row with no PASSED result."
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*jenkins/test*")
        | filter job_result != "ABORTED" and job_result != "FAILURE"
        | parse content, "JSON:j"
        | expand tc = j[testsuite][testcase]
        | fieldsAdd testname = toString(tc[testname]), failed = if(toString(tc[status]) == "PASSED", 0, else: 1)
        | fieldsAdd name = replaceString(replaceString(job_name,
                            "App-Ops-OpenOps/app-check-group/Real Time Check/", "App-Ops-OpenOps/app-check-jobs/Functional/"),
                            "%20", " ")
        | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
        | filter isNotNull(cfg.application)
        | fieldsAdd application = cfg.application, pager_duty = coalesce(toString(cfg.pager_duty), "1")
        | makeTimeseries fail = sum(failed, default: 0), ok = sum(1 - failed, default: 0), by:{ application, testname, pager_duty }, interval:1m
        | fieldsAdd fail_n = arrayMovingSum(fail, ${local.jenkins_functional_window_min}), ok_n = arrayMovingSum(ok, ${local.jenkins_functional_window_min})
        | fieldsAdd consecutive_ng = if(fail_n[] >= 2 and ok_n[] == 0, 1, else: 0)
        | fieldsKeep timeframe, interval, application, testname, pager_duty, consecutive_ng
      EOT
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "jenkins_app_monitoring" {
  for_each = local.jenkins_detectors

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "3"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "1"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = each.value.name
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "{dims:application}"
      }
      property {
        # 0 = Splunk "PagerDuty Disable" apps; the standard flow needs a rule to skip paging for these
        key   = "pagerduty.enabled"
        value = "{dims:pager_duty}"
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: 35-http-response-outlier-alert-transform/35-http-response-outlier-alert-transform.tf
# ##########################################################################

# Splunk "HTTP Response Check Outlier" → Dynatrace auto-adaptive detector
#
#   index="jenkins_console" sourcetype="text:jenkins" "[HTTP Monitor]" job_name="HTTP Monitor - AGGW LB"
#   | eval duration=replace(duration,"s","")
#   | timechart span=10m max(duration) as responsetime | head 1000
#   | streamstats window=200 median, median absolute deviation (MAD)
#   | outlier if responsetime < median - 20*MAD or > median + 20*MAD
#   | head 1 | search isOutlier=1
#   Last 24 hours, every 10 minutes, email masayuki.yasuda, subject 【TEST】 (a test alert)
#
# Dynatrace: the auto-adaptive analyzer learns the baseline and the normal fluctuation itself,
# which is what the streamstats median and MAD code did by hand. ABOVE only: the analyzer
# supports ABOVE or BELOW, and a faster-than-usual response is not an incident.
#
# CONFIRM before apply:
#   1. log.source for jenkins_console, and how the AGGW LB job is identified   (check.dql 1)
#   2. How duration appears in the line (e.g. "duration=0.532s")             (check.dql 2)

resource "dynatrace_davis_anomaly_detectors" "jenkins_aggw_lb_response_outlier" {
  title       = "Prod_Jenkins_AGGWLB_ResponseTimeOutlier_Normal"
  description = "HTTP Monitor - AGGW LB response time is far above its learned baseline."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.AutoAdaptiveAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*jenkins*console*")
          | filter contains(content, "[HTTP Monitor]")
          | filter contains(log.source, "HTTP%20Monitor%20-%20AGGW%20LB") or contains(content, "HTTP Monitor - AGGW LB")
          | parse content, "LD 'duration' LD DOUBLE:responsetime 's'"
          | makeTimeseries responsetime = max(responsetime), interval:1m
          | fieldsAdd responsetime = arrayMovingMax(responsetime, 10)
        EOT
      }
      analyzer_input_field {
        # How many "normal fluctuations" above the baseline count as a violation.
        # Splunk used 20 x MAD, which is very wide; start at 5 and tune with the preview.
        key   = "numberOfSignalFluctuations"
        value = "5"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "5"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "10"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "10"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_Jenkins_AGGWLB_ResponseTimeOutlier_Normal"
      }
      property {
        key   = "event.description"
        value = "HTTP Monitor - AGGW LB response time is far above its learned baseline (10-minute max response time)."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "AGGW LB"
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: 36-broker-policy-undefined-error-alert/36-broker-policy-undefined-error-alert.tf
# ##########################################################################

# Splunk alert → Dynatrace detector (1 Splunk alert → 1 detector, no workflow)
#
#   ALJ Broker Policy Maintenance: Cannot read properties of undefined
#     index=brokerpolicymaintenance-prod-axa-li-jp *Cannot read properties of undefined*
#     | timechart span=1m count | where count > 50
#     Last 5 minutes, cron */1, results > 0, trigger "For each result", no throttle
#     Email: Splunk Alert: $name$ (Normal) to 2 recipients
#
# CONFIRM before apply (check.dql query 1):
#   The Splunk index name looks like an OpenShift (OCP) namespace → guessed k8s.namespace.name.
#   If the logs arrive with another attribute, change the first filter line only.

resource "dynatrace_davis_anomaly_detectors" "broker_policy_undefined_error" {
  title       = "Prod_BrokerPolicyMaintenance_UndefinedPropertyError_Normal"
  description = "More than 50 'Cannot read properties of undefined' errors in one minute in brokerpolicymaintenance (prod). Check the OCP pod status."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter k8s.namespace.name == "brokerpolicymaintenance-prod-axa-li-jp"
          | filter contains(content, "Cannot read properties of undefined", caseSensitive: false)
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "50"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "Prod_BrokerPolicyMaintenance_UndefinedPropertyError_Normal"
      }
      property {
        key   = "event.description"
        value = "More than 50 'Cannot read properties of undefined' errors in one minute in brokerpolicymaintenance (prod). Check the OCP pod status."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Broker Policy Maintenance"
      }
    }
  }

  execution_settings {}
}
