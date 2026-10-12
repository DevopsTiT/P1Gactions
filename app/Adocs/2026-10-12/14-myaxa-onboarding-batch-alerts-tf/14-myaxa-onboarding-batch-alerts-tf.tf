# Source: Migration/CW/configuration 2/myaxa-onboarding-batch.tf
#   "dynatrace_log_alert" resources. That type does not exist in the dynatrace-oss/dynatrace provider.
#   Rewritten as Records detectors (Davis anomaly detectors).
#
# Alerts 1-4 converted. ALERT 5 "sendNotificationsQueueConsumer Error" (line 182+) was not in the screenshots.
#
# All four had:
#   Cron */5 * * * *, last 5 minutes, expires 24, results > 0, once, no throttle
#   Email only to 6 recipients, priority HIGH (not copied) → alert.severity = "high"
#   No PagerDuty action → pagerduty.enabled = "0"  (names end in "_High": confirm whether they should page)
#   description = "Optional" placeholders → real descriptions written
#
# CONFIRM before apply (check.dql):
#   1. ALERT 4 ("message sending failed") reads, from a rotated photo, as the SAME text as Alert 3:
#      "sendNotificationsQueueConsumer :: email sending failed". It is probably meant to be
#      "sendNotificationsQueueConsumer :: message sending failed". Kept as read; fix if query 3 confirms.
#   2. Alerts 3 and 4 were read from rotated photos.
#   3. All contains() are case-sensitive, as in the original.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# ==============================================
# ALERT 1: sendNotifications Error
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "emma_send_notifications_error" {
  title       = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotifications_error_High"
  description = "myaxa-onboarding-batch logged 'sendNotifications :: error' in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "myaxa-onboarding-batch")
          | filter contains(content, "sendNotifications :: error")
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
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
        value = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotifications_error_High"
      }
      property {
        key   = "event.description"
        value = "sendNotifications failed in myaxa-onboarding-batch. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Emma myaxa-onboarding-batch"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

# ==============================================
# ALERT 2: handleOnboardedCustomers Error
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "emma_handle_onboarded_customers_error" {
  title       = "Prod_Life_Emma_myaxa-onboarding-batch_handleOnboardedCustomers_error_High"
  description = "myaxa-onboarding-batch logged 'handleOnboardedCustomers :: error' in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "myaxa-onboarding-batch")
          | filter contains(content, "handleOnboardedCustomers :: error")
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
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
        value = "Prod_Life_Emma_myaxa-onboarding-batch_handleOnboardedCustomers_error_High"
      }
      property {
        key   = "event.description"
        value = "handleOnboardedCustomers failed in myaxa-onboarding-batch. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Emma myaxa-onboarding-batch"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

# ==============================================
# ALERT 3: sendNotificationsQueueConsumer Email Sending Failed
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "emma_queue_consumer_email_sending_failed" {
  title       = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotificationsQueueConsumer_email_sending_failed_High"
  description = "myaxa-onboarding-batch queue consumer failed to send an email in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "myaxa-onboarding-batch")
          | filter contains(content, "sendNotificationsQueueConsumer :: email sending failed")
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
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
        value = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotificationsQueueConsumer_email_sending_failed_High"
      }
      property {
        key   = "event.description"
        value = "sendNotificationsQueueConsumer could not send an email. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Emma myaxa-onboarding-batch"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

# ==============================================
# ALERT 4: sendNotificationsQueueConsumer Message Sending Failed
#   Filter text reads the same as Alert 3 (see CONFIRM 1). Likely intended:
#   "sendNotificationsQueueConsumer :: message sending failed"
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "emma_queue_consumer_message_sending_failed" {
  title       = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotificationsQueueConsumer_message_sending_failed_High"
  description = "myaxa-onboarding-batch queue consumer failed to send a message in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "myaxa-onboarding-batch")
          | filter contains(content, "sendNotificationsQueueConsumer :: email sending failed")
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
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
        value = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotificationsQueueConsumer_message_sending_failed_High"
      }
      property {
        key   = "event.description"
        value = "sendNotificationsQueueConsumer could not send a message. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Emma myaxa-onboarding-batch"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
