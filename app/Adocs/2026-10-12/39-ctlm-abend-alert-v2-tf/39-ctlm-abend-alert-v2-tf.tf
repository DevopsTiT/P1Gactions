terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: sourcetype=controlm_alert message="Ended not OK"
#   | eval system, RUN_COUNT, JOB_CODE=job_name+current_time, HH, MM, SS
#   | table ... | join type=left job_name [search sourcetype=controlm_def_ver_jobs ...]
# Last 5 minutes, cron every minute, more than 0 results, for each result,
# throttle by JOB_CODE for 6 minutes.
# The parse lines assume the Control-M alert line uses key=value pairs.
# Run check query 1 and change the patterns if the format differs.
# The left join (cmd_line, owner) is left out of the detector. See check query 4.
resource "dynatrace_davis_anomaly_detectors" "ctlm_abend_alert_v2" {
  title       = "CTL-M アベンドアラートV2"
  description = "Control-M job ended not OK (abend). One problem per JOB_CODE (job_name plus current_time), so each abend alerts once."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(content, "Ended not OK", caseSensitive:false)
          | parse content, "LD 'job_name=' NSPACE:job_name"
          | parse content, "LD 'data_center=' NSPACE:data_center"
          | parse content, "LD 'application=' NSPACE:application"
          | parse content, "LD 'run_counter=' INT:run_counter"
          | parse content, "LD 'current_time=' NSPACE:current_time"
          | parse content, "LD 'memname=' NSPACE:memname"
          | parse content, "LD 'group_name=' NSPACE:group_name"
          | parse content, "LD 'node_id=' NSPACE:node_id"
          | filter isNotNull(job_name)
          | fieldsAdd system = if(data_center == "Server#1", "Open",
                                else: if(data_center == "mainframe#1", "MF", else: "unknown")),
                      RUN_COUNT = if(application == "NO_APPL", run_counter + 1, else: run_counter),
                      JOB_CODE = concat(job_name, current_time),
                      HH = substring(current_time, from:8, to:10),
                      MM = substring(current_time, from:10, to:12),
                      SS = substring(current_time, from:12, to:14)
          | fields timestamp, JOB_CODE, HH, MM, SS, RUN_COUNT, system, job_name, application,
                   data_center, group_name, memname, node_id, host.name, content
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "JOB_CODE"
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
        value = "Control-M job abend"
      }
      property {
        key   = "event.description"
        value = "A Control-M job ended not OK. See job_name, system, RUN_COUNT and HH:MM:SS on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "controlm"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
