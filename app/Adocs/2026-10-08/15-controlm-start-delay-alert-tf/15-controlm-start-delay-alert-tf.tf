# Splunk: Control-M 遅延アラート (Control-M start time delay alert)
#   sourcetype=controlm_alert "Start Time Delay"
#   | join type=left job_name [ inputlookup controlm_addresslist.csv | eval job_name=JobID | table job_name,Method,Main,Sub ]
#   | join type=left job_name [ inputlookup controlm_job_Definition.csv | CMD_STRING, node_id, owner ]
#   | join type=left job_name [ inputlookup controlm_SpecificContact.csv | job_name,Email,TITLE,BODY,Comment ]
#   | system (Server#1=Open, mainframe#1=MF#1, mainframe#3=MF#3), RUN_COUNT, JOB_CODE=job_name+current_time
#   | RunInfo  = APL- jobs: run_counter:Method (or 未登録), other jobs: run_counter+1
#   | MailTitle = TITLE from SpecificContact, else "Splunk Alert: <job> (<system>) Delay(<RunInfo>) [HH:MM:SS]"
#   | MailBody  = BODY from SpecificContact, else "Start Time Delay(...)" text with Main, Sub, job info
#   cron */2, Last 5 minutes, results > 0, For each result, throttle on JOB_CODE 5 minutes
#   Actions: Output results to lookup controlmalertabendhistory2.csv (append), Send email
#
# Dynatrace: one problem per delay event (JOB_CODE). MailTitle and MailBody are kept as fields.
#   The "append to controlmalertabendhistory2.csv" action has no detector equivalent:
#   the delay rows stay in Grail logs, so a dashboard or notebook can query history instead.
#
# CONFIRM before apply (check.dql):
#   1. log.source value for controlm_alert (query 1)
#   2. Fields exist as attributes: job_name, data_center, application, run_counter, current_time,
#      host_time, group_name (query 2)
#   3. Lookups uploaded with a job_name column:
#      /lookups/controlm/addresslist       (job_name, Method, Main, Sub)   Splunk column is JobID
#      /lookups/controlm/job_definition    (job_name, CMD_STRING, node_id, owner)
#      /lookups/controlm/specific_contact  (job_name, Email, TITLE, BODY, Comment)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "controlm_start_delay_alert" {
  title       = "Control-M 遅延アラート"
  description = "A Control-M job reported Start Time Delay in the last 5 minutes. One problem per delay event (job_name + current_time)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter matchesValue(log.source, "*controlm_alert*")
          | filter contains(content, "Start Time Delay", caseSensitive:false)
          | lookup [ load "/lookups/controlm/addresslist" ], sourceField:job_name, lookupField:job_name, prefix:"addr."
          | lookup [ load "/lookups/controlm/job_definition" ], sourceField:job_name, lookupField:job_name, prefix:"def."
          | lookup [ load "/lookups/controlm/specific_contact" ], sourceField:job_name, lookupField:job_name, prefix:"sc."
          | fieldsAdd system = if(data_center == "Server#1", "Open",
                               else: if(data_center == "mainframe#1", "MF#1",
                               else: if(data_center == "mainframe#3", "MF#3", else: "unknown")))
          | fieldsAdd RUN_COUNT = if(application == "NO_APPL", toLong(run_counter) + 1, else: toLong(run_counter))
          | fieldsAdd JOB_CODE = concat(job_name, current_time)
          | fieldsAdd HMS = concat(substring(current_time, from:8, to:10), ":", substring(current_time, from:10, to:12), ":", substring(current_time, from:12, to:14))
          | fieldsAdd RunInfo = if(startsWith(application, "APL-"),
                                   concat(toString(run_counter), ":", coalesce(addr.Method, "未登録")),
                                   else: toString(toLong(run_counter) + 1))
          | fieldsAdd MailTitle = if(isNotNull(sc.TITLE) and sc.TITLE != "", sc.TITLE,
                                     else: concat("Splunk Alert: ", job_name, " (", system, ") Delay(", RunInfo, ") [", HMS, "]"))
          | fieldsAdd MailBody = if(isNotNull(sc.BODY) and sc.BODY != "", sc.BODY,
                                    else: concat("Start Time Delay(", RunInfo, ")\n[", toString(host_time), "]\n",
                                                 "Main=", coalesce(addr.Main, ""), "\nSub=", coalesce(addr.Sub, ""), "\n\n",
                                                 coalesce(application, ""), "/", coalesce(group_name, ""), "/", job_name, "\n",
                                                 coalesce(def.CMD_STRING, ""), "\n",
                                                 coalesce(def.owner, ""), "/", coalesce(def.node_id, ""), "\n",
                                                 JOB_CODE))
          | dedup JOB_CODE
          | fields timestamp, JOB_CODE, job_name, system, application, group_name, RunInfo, RUN_COUNT,
                   addr.Main, addr.Sub, sc.Email, MailTitle, MailBody
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
        value = "Control-M 遅延アラート"
      }
      property {
        key   = "event.description"
        value = "Control-Mジョブの開始が遅延しています（Start Time Delay）。MailTitle と MailBody を確認してください。"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Control-M"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
