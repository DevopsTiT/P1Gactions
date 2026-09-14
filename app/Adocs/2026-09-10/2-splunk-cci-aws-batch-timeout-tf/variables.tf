variable "pagerduty_integration_key_cci_batch" {
  type        = string
  description = "PagerDuty integration key for CCI_AWS_Batch Time Out (from Splunk alert action)"
  sensitive   = true
}

variable "splunk_alert_owner" {
  type        = string
  description = "Splunk ACL owner for the saved search"
  default     = "admin"
}

variable "splunk_alert_sharing" {
  type        = string
  description = "user | app | global"
  default     = "app"
}

variable "splunk_alert_app" {
  type        = string
  description = "Splunk app context for ACL"
  default     = "search"
}
