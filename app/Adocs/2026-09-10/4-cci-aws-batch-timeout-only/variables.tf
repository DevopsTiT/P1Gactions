variable "pagerduty_integration_key" {
  type        = string
  description = "PagerDuty integration key from Splunk alert CCI_AWS_Batch Time Out"
  sensitive   = true
}

variable "splunk_alert_owner" {
  type    = string
  default = "admin"
}

variable "splunk_alert_sharing" {
  type    = string
  default = "app"
}

variable "splunk_alert_app" {
  type    = string
  default = "search"
}
