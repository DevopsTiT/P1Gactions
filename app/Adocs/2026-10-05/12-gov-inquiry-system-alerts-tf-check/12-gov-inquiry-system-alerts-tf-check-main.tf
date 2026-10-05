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
