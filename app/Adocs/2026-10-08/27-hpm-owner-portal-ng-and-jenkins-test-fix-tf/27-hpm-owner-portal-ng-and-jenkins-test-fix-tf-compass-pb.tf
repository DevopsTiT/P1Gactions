# Fix of 2026-10-08 seq 23 (Prod_Life_CompassPB_RealTimeAndFunctionalCheck_NG).
#   Seq 23 only kept App-Ops-OpenOps jobs and only counted Real Time results.
#   Same resource name as seq 23, so apply updates it in place. Window 2 hours, PagerDuty Enable, remarks kept.

resource "dynatrace_davis_anomaly_detectors" "compass_pb_realtime_functional_ng" {
  title       = "Prod_Life_CompassPB_RealTimeAndFunctionalCheck_NG"
  description = "Compass AG Jenkins check returned 2 or more non-SUCCESS results in the last 2 hours with no SUCCESS. One problem per job."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-2h
          | filter matchesValue(host.name, "ceaa2099*")
          | filter contains(content, "build_report")
          | parse content, "JSON:j"
          | filter isNull(j[job_duration])
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result])
          | filter isNotNull(job_name) and job_result != "ABORTED" and job_result != "FAILURE"
          | fieldsAdd is_functional = contains(job_name, "App-Ops-OpenOps/app-check-jobs/Functional/")
          | fieldsAdd remark = if(contains(content, "OKメンテナンス中"), "OKメンテナンス中")
          | fieldsAdd project = replaceString(replaceString(job_name, "%20", " "), "App-Ops-OpenOps/app-check-group/Real Time Check/", "App-Ops-OpenOps/app-check-jobs/Functional/")
          | fieldsAdd name = replaceString(replaceString(project, "job/", ""), "/App", "App")
          | fieldsAdd name = if(endsWith(name, "/"), substring(name, from:0, to:stringLength(name) - 1), else: name)
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
          | filter cfg.application == "Compass AG"
          | fieldsAdd application = cfg.application
          | summarize fails = countIf(not is_functional and job_result != "SUCCESS"),
                      oks = countIf(not is_functional and job_result == "SUCCESS"),
                      functional_runs = countIf(is_functional),
                      remarks = collectDistinct(remark),
                      last_seen = max(timestamp),
                      by:{ application, name }
          | filter fails >= 2 and oks == 0
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "application"
      }
      analyzer_input_field {
        key   = "alertIdentityFields[1]"
        value = "name"
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
        value = "Prod_Life_CompassPB_RealTimeAndFunctionalCheck_NG"
      }
      property {
        key   = "event.description"
        value = "Compass AG Jenkins check is NG (2+ non-SUCCESS results, no SUCCESS, last 2 hours). See name, fails and remarks on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Compass AG"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
