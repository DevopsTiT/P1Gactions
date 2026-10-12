# Source: Migration/CW/configuration 2/gov-inquiry-system.tf
#   Seven "dynatrace_log_alert" resources. That type does not exist in the dynatrace-oss/dynatrace provider.
#   All rewritten as Records detectors (Davis anomaly detectors).
#
# All seven had:
#   Cron */5 * * * *, last 5 minutes, expires 24, results > 0, once, no throttle
#   Email only to one distribution list, priority Normal (not copied) → workflow
#   No PagerDuty action → pagerduty.enabled = "0"
#
# Severity:
#   Alerts 1, 2, 3, 7 are file SUMMARY notices (information, not failures) → "low"
#   Alerts 4, 5, 6 are error notices → "medium"
#
# Identity:
#   Alerts 1, 2, 3 parse fileName → one problem per file (alertIdentityFields = fileName)
#   Alerts 4 to 7 → one problem per log group
#
# Removed: "sort timestamp desc" and "limit 100" (a detector only needs rows to exist)
#
# CONFIRM before apply (check.dql):
#   1. ALERT 2 could not be read (rotated, blurry photo). Its query is a PLACEHOLDER and enabled = false.
#      Send a straight screenshot of lines 50-95 to finish it.
#   2. Alert 3 and Alert 4 were read from rotated photos: check the log group names
#      (validateAndComputeAnswer, logFailure) and the fileCategory value (REQUEST_FILE).
#   3. WORD:fileName stops at "." and "-". "ND_20261012.csv" becomes "ND_20261012". Query 2 shows real names.
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
# ALERT 1: ND File Detailed Summary
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "gov_inquiry_nd_file_detailed_summary" {
  title       = "[gov-inquiry-system] ND file detailed summary"
  description = "Extract ND file summary with detailed metrics"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseNdAndUpdateDb")
          | filter contains(content, "Biz file summary")
          | filter contains(content, "fileCategory:ND_SEARCH_RESULT_FILE")
          | parse content, "LD 'fileName:' WORD:fileName"
          | parse content, "LD 'searchResultCount:' INT:searchResultCount"
          | parse content, "LD 'noContractCount:' INT:noContractCount"
          | parse content, "LD 'contractExistsCount:' INT:contractExistsCount"
          | fields timestamp, fileName, searchResultCount, noContractCount, contractExistsCount
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "fileName"
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
        value = "[Gov Inquiry System] ND file detailed summary"
      }
      property {
        key   = "event.description"
        value = "ND search result file processed. See fileName, searchResultCount, noContractCount and contractExistsCount on the problem."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "gov-inquiry-system"
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
# ALERT 2: Answer File Detailed Summary
#   PLACEHOLDER — the screenshot was unreadable. Fill in the log group, fileCategory and parse lines, then set enabled = true.
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "gov_inquiry_answer_file_detailed_summary" {
  title       = "[gov-inquiry-system] answer file detailed summary"
  description = "Extract answer file summary with detailed metrics"
  enabled     = false
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-REPLACE_ME")
          | filter contains(content, "Biz file summary")
          | filter contains(content, "fileCategory:REPLACE_ME")
          | parse content, "LD 'fileName:' WORD:fileName"
          | fields timestamp, fileName
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "fileName"
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
        value = "[Gov Inquiry System] answer file detailed summary"
      }
      property {
        key   = "event.description"
        value = "Answer file processed. See fileName and the counts on the problem."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "gov-inquiry-system"
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
# ALERT 3: Request File Detailed Summary
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "gov_inquiry_request_file_detailed_summary" {
  title       = "[gov-inquiry-system] request file detailed summary"
  description = "Extract request file summary with detailed metrics"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-validateAndComputeAnswer")
          | filter contains(content, "Biz file summary")
          | filter contains(content, "fileCategory:REQUEST_FILE")
          | parse content, "LD 'fileName:' WORD:fileName"
          | parse content, "LD 'requestingGovernmentCount:' INT:requestingGovernmentCount"
          | parse content, "LD 'contractRequestCount:' INT:contractRequestCount"
          | parse content, "LD 'precheckResultCount:' INT:precheckResultCount"
          | fields timestamp, fileName, requestingGovernmentCount, contractRequestCount, precheckResultCount
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "fileName"
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
        value = "[Gov Inquiry System] request file detailed summary"
      }
      property {
        key   = "event.description"
        value = "Request file processed. See fileName, requestingGovernmentCount, contractRequestCount and precheckResultCount on the problem."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "gov-inquiry-system"
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
# ALERT 4: General Error
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "gov_inquiry_general_error" {
  title       = "gov-inquiry-system General Error"
  description = "A General Error occurred in the gov-inquiry-system"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-logFailure")
          | filter contains(content, "level:ERROR")
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
        value = "gov-inquiry-system: General Error"
      }
      property {
        key   = "event.description"
        value = "A general error occurred in gov-inquiry-system. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "gov-inquiry-system"
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
# ALERT 5: Error File Processing
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "gov_inquiry_error_file_processing" {
  title       = "gov-inquiry-system Error File Processing"
  description = "Error file is transferred from pipitLINQ"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseErrorFileAndUpdateDb")
          | filter contains(content, "ParseErrorFileAndUpdateDB")
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
        value = "gov-inquiry-system: error file processing"
      }
      property {
        key   = "event.description"
        value = "An error file was transferred from pipitLINQ and processed. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "gov-inquiry-system"
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
# ALERT 6: System Error File Processing
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "gov_inquiry_system_error_file_processing" {
  title       = "gov-inquiry-system System Error File Processing"
  description = "System error file is transferred from the kyoto GW"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseSysErrorFileAndUpdateDb")
          | filter contains(content, "parseGatewaySysErrorFileAndUpdateDbEffect")
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
        value = "gov-inquiry-system: system error file"
      }
      property {
        key   = "event.description"
        value = "A system error file was transferred from the Kyoto gateway and processed. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "gov-inquiry-system"
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
# ALERT 7: MDM File Summary
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "gov_inquiry_mdm_file_summary" {
  title       = "[gov-inquiry-system] MDM file summary"
  description = "MDM file summary monitoring"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseMdmResponseAndUpdateDb")
          | filter contains(content, "Biz file summary")
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
        value = "[Gov Inquiry System] MDM file summary"
      }
      property {
        key   = "event.description"
        value = "MDM response file processed. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "gov-inquiry-system"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
