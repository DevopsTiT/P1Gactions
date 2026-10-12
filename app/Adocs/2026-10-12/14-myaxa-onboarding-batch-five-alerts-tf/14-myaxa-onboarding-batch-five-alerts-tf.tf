# Source: Migration/CW/configuration 2/myaxa-onboarding-batch.tf
#   Five "dynatrace_log_alert" resources. That type does not exist in the dynatrace-oss/dynatrace provider.
#   All rewritten as Records detectors (Davis anomaly detectors).
#
# All five had:
#   Cron */5 * * * *, last 5 minutes, expires 24, results > 0, once, no throttle
#   description = "Optional" (placeholder)
#   Email only, priority HIGH, 6 recipients (not copied) → alert.severity = "high"
#   No PagerDuty action → pagerduty.enabled = "0"
#
# Filters are kept AS WRITTEN. CONFIRM before apply (check.dql):
#   1. Alert 4 (message sending failed) uses the SAME text as Alert 3: "email sending failed".
#      Probably a copy-paste slip; likely meant "message sending failed". Read from a rotated photo.
#   2. Alert 5 (QueueConsumer error) uses the SAME text as Alert 1: "sendNotifications :: error".
#      That does NOT match "sendNotificationsQueueConsumer :: error". Likely a copy-paste slip. Read from a rotated photo.
#   3. Alert 2's second filter "handleOnboardedCustomers" is already covered by the first.
#   4. All contains() here are case-sensitive, as in the original.

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
  description = "myaxa-onboarding-batch logged 'sendNotifications :: error'."
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
  description = "myaxa-onboarding-batch logged 'handleOnboardedCustomers :: error'."
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
  description = "myaxa-onboarding-batch logged 'sendNotificationsQueueConsumer :: email sending failed'."
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
        value = "The notification queue consumer failed to send an email. See the matching log lines (content) on the problem."
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
#   AS WRITTEN: same text as Alert 3 ("email sending failed"). See CONFIRM item 1.
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "emma_queue_consumer_message_sending_failed" {
  title       = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotificationsQueueConsumer_message_sending_failed_High"
  description = "myaxa-onboarding-batch queue consumer message sending failed."
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
        value = "The notification queue consumer failed to send a message. See the matching log lines (content) on the problem."
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
# ALERT 5: sendNotificationsQueueConsumer Error
#   AS WRITTEN: same text as Alert 1 ("sendNotifications :: error"). See CONFIRM item 2.
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "emma_queue_consumer_error" {
  title       = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotificationsQueueConsumer_error_High"
  description = "myaxa-onboarding-batch queue consumer error."
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
        value = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotificationsQueueConsumer_error_High"
      }
      property {
        key   = "event.description"
        value = "The notification queue consumer logged an error. See the matching log lines (content) on the problem."
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
