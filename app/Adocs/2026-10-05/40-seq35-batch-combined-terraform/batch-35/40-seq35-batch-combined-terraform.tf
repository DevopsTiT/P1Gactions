# ==========================================================================
# Seq 35 screenshot batch (9 screenshots, 4 Splunk alerts) → one Terraform file
#
#   Splunk alert                              Dynatrace detector (title)
#   Application Monitoring Alert - URL        jenkins_app_monitoring["jenkins_url_check_failed"]
#   Application Monitoring Alert - URL for      Prod_Jenkins_AppMonitoring_URLCheckFailed_High
#     MyAXA
#   Application Monitoring Alert - function   jenkins_app_monitoring["jenkins_functional_check_failed"]
#                                               Prod_Jenkins_AppMonitoring_FunctionalCheckFailed_High
#   HTTP Response Check Outlier 【TEST】      jenkins_aggw_lb_response_outlier
#                                               Prod_Jenkins_AGGWLB_ResponseTimeOutlier_Normal
#
#   Total: 3 detectors, 0 workflows.
#
# Sources: Jenkins part = seq 34 (unchanged). Outlier part = seq 35 with the two seq 38 fixes:
#   1. "{violating_samples}" removed from event.description (not a Dynatrace placeholder)
#   2. arrayMovingMax(responsetime, 10) added so a job that does not log every minute
#      can still reach 5 violating minutes
#
# Do not apply together with the seq 39 file in one folder: both contain jenkins_app_monitoring.
# Use the seq 34-35-36 file in this folder instead if you want all three batches.
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


# ### PART 1: Jenkins Application Monitoring - from seq 34 ###

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

# ### PART 2: HTTP Response Check Outlier - from seq 35 (fixed) ###

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
