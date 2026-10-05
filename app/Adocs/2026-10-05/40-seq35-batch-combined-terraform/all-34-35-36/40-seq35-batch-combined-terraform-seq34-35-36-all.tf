# ==========================================================================
# Jenkins screenshot batches seq 34 + 35 + 36, duplicates removed → one Terraform file
#
#   Batch    Splunk alerts in screenshots                         Handled by
#   seq 34   10 Application Monitoring alerts                     jenkins_app_monitoring (2 detectors)
#   seq 35   URL, URL for MyAXA, function (repeats of seq 34)     jenkins_app_monitoring (no new code)
#            HTTP Response Check Outlier                          jenkins_aggw_lb_response_outlier
#   seq 36   7 Application Monitoring alerts (repeats of seq 34)  jenkins_app_monitoring (no new code)
#            ALJ Broker Policy Maintenance undefined error        broker_policy_undefined_error
#
#   Unique Splunk alerts: 12 → Dynatrace: 4 detectors, 0 workflows.
#
# Outlier detector includes the two seq 38 fixes (placeholder removed, arrayMovingMax added).
# PagerDuty keys from the screenshots are NOT copied; paging uses the standard flow.
#
# This file replaces seq 34, 35, 36, 39 and the seq 35 batch file. Apply only one of them.
#
# CONFIRM before apply:
#   1. Jenkins log.source values and formats (seq 34 check.dql, seq 35 check.dql)
#   2. Upload /lookups/jenkins/configuration (job_name, application, pager_duty)
#   3. Splunk macro definitions check_maintenance_window and add_alert_info
#   4. Broker logs found by k8s.namespace.name (seq 36 check.dql 1)
#   5. Whether the 【TEST】 outlier alert should go live
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

# ### PART 3: Broker Policy Maintenance - from seq 36 ###

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
