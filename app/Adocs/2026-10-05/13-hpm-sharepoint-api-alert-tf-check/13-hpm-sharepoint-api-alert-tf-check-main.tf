# ALERT: Prod_Life_HPM_SharepointAPILambdaError_Normal
# Daily 10:00 JST digest of ERROR lines from hpm-sharepoint-api-prod (S3 <-> SharePoint transfers)

locals {
  hpm_sp_errors = <<-EOT
    | filter aws.log_group == "/aws/lambda/hpm-sharepoint-api-prod"
    | filter status == "ERROR" or contains(content, "ERROR", caseSensitive: false)
  EOT
}

resource "dynatrace_automation_workflow" "hpm_sharepoint_api_lambda_error" {
  title       = "Prod_Life_HPM_SharepointAPILambdaError_Normal"
  description = "To check Lambda error: failure transferring files from S3 to SharePoint and SharePoint to S3. Daily 10:00 JST digest of the last 24 hours."

  tasks {
    task {
      name        = "count_errors"
      description = "Total ERROR lines in the last 24 hours"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = "fetch logs, from:now()-24h\n${local.hpm_sp_errors}| summarize total = count()"
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "list_errors"
      description = "Latest 100 ERROR lines"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = "fetch logs, from:now()-24h\n${local.hpm_sp_errors}| fields timestamp, status, content\n| sort timestamp desc\n| limit 100"
      })
      position {
        x = 1
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the HPM team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "naoya.sota@axa.co.jp",
          "chungyueh.chiu@axa.co.jp",
          "hiroshi.annaka@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Prod_Life_HPM_SharepointAPILambdaError_Normal"
        content = "{{ result(\"count_errors\").records[0].total }} ERROR line(s) from hpm-sharepoint-api-prod in the last 24 hours. Latest 100:\n\n{% for r in result(\"list_errors\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          count_errors = "SUCCESS"
          list_errors  = "SUCCESS"
        }
        custom = "{{ result(\"count_errors\").records[0].total > 0 }}"
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
        cron = "0 10 * * *"
      }
    }
  }
}
