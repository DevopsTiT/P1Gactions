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
