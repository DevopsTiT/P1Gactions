# ==========================================================================
# Seq 36 screenshot batch (22 screenshots, 8 Splunk alerts) → one Terraform file
#
#   Splunk alert                                              Dynatrace detector (title)
#   ALJ Broker Policy Maintenance: Cannot read properties     broker_policy_undefined_error
#     of undefined                                              Prod_BrokerPolicyMaintenance_UndefinedPropertyError_Normal
#   Application Monitoring Alert - URL                        jenkins_app_monitoring["jenkins_url_check_failed"]
#   Application Monitoring Alert - URL for MyAXA                Prod_Jenkins_AppMonitoring_URLCheckFailed_High
#   Application Monitoring Alert - function                   jenkins_app_monitoring["jenkins_functional_check_failed"]
#   ... - function for AG Portal   (AG Portal NTTGW)            Prod_Jenkins_AppMonitoring_FunctionalCheckFailed_High
#   ... - function for BancaPotal  (Banca Portal)
#   ... - function for Compass     (Compass, extra メンテナンス中 rex)
#   ... - function for Compass PB  (Compass AG)
#
#   Total: 3 detectors, 0 workflows.
#   The two Jenkins detectors split by application, so they also cover Cockpit360, FCR and ICM
#   (seq 34 screenshots) without extra code.
#
# Sources: Jenkins part = seq 34 (unchanged), Broker part = seq 36 (unchanged).
# PagerDuty keys from the screenshots are NOT copied; paging uses the standard flow
# with the pagerduty.enabled and app.name properties.
#
# CONFIRM before apply:
#   1. Jenkins log.source values and line formats (seq 34 check.dql 1 to 3)
#   2. Upload /lookups/jenkins/configuration (job_name, application, pager_duty)
#   3. Definitions of the Splunk macros check_maintenance_window and add_alert_info
#   4. Broker logs found by k8s.namespace.name (seq 36 check.dql 1)
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
# PART 1: Jenkins Application Monitoring (7 alerts in this batch) - from seq 34
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
# PART 2: Broker Policy Maintenance (1 alert) - from seq 36
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
