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
